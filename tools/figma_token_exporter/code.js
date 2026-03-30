figma.showUI(__html__, { width: 320, height: 240 });

const variableMap = {}; // path -> Variable ID
const collections = {}; // name -> VariableCollection

figma.ui.onmessage = async (msg) => {
  if (msg.type === 'process-tokens') {
    const tokens = msg.data;
    try {
      await processTokens(tokens);
      figma.ui.postMessage({ type: 'status', text: '✅ 成功! 变量已同步。' });
    } catch (err) {
      figma.ui.postMessage({ type: 'status', text: '❌ 错误: ' + err.message });
      console.error(err);
    }
  }
};

async function processTokens(tokens) {
  // 1. 创建或获取 Collections
  const colNames = ['Primitive', 'Semantic', 'Component'];
  for (const name of colNames) {
    let col = (await figma.variables.getLocalVariableCollectionsAsync()).find(c => c.name === name);
    if (!col) {
      col = figma.variables.createVariableCollection(name);
    }
    // 确保有 Light 和 Dark 模式 (对应 Semantic 和 Component)
    if (name !== 'Primitive') {
      if (col.modes.length < 2) {
        col.addMode('Dark');
        col.renameMode(col.modes[0].modeId, 'Light');
      }
    }
    collections[name] = col;
  }

  // 2. 第一遍: 处理 Primitive (只处理原始值)
  if (tokens.primitive) {
    await traverseAndCreate(tokens.primitive, 'Primitive', []);
  }

  // 3. 第二遍: 处理 Semantic (建立对 Primitive 的引用)
  if (tokens.semantic) {
    await traverseAndCreate(tokens.semantic, 'Semantic', []);
  }

  // 4. 第三遍: 处理 Component (建立对 Semantic 的引用)
  if (tokens.component) {
    await traverseAndCreate(tokens.component, 'Component', []);
  }
}

function isModeObject(value, colName) {
  // Primitive 层不应该有 mode，只有 Semantic 和 Component
  if (colName === 'Primitive') return false;
  
  // 检查对象键是否都是模式名（light, dark 等）
  const keys = Object.keys(value);
  const validModes = ['light', 'dark'];
  
  // 如果所有键都是有效的 mode，则这是一个 mode 对象
  return keys.length > 0 && keys.every(k => validModes.includes(k));
}

async function traverseAndCreate(node, colName, pathSegments) {
  const collection = collections[colName];
  const modeIds = collection.modes.map(m => m.modeId);

  for (const key in node) {
    const value = node[key];
    const currentPath = [...pathSegments, key];
    const fullPath = currentPath.join('/');

    if (typeof value === 'object' && value !== null && !isColor(value) && !isAlias(value)) {
      // 检查是否是 mode 对象 (light/dark 等)
      if (isModeObject(value, colName)) {
        // 作为一个变量处理，不再递归
        await createVariable(collection, fullPath, value, colName);
      } else {
        // 递归处理子节点
        await traverseAndCreate(value, colName, currentPath);
      }
    } else {
      // 创建或更新变量
      await createVariable(collection, fullPath, value, colName);
    }
  }
}


async function createVariable(collection, path, value, colName) {
  // 获取现有变量列表
  const vars = await figma.variables.getLocalVariablesAsync();
  let v = vars.find(variable => 
    variable.name === path && variable.variableCollectionId === collection.id
  );
  
  // 如果变量已存在，直接复用
  if (v) {
    // 更新现有变量的值
    collection.modes.forEach(mode => {
      const val = resolveValue(value, mode.name);
      if (typeof val === 'string' && val.startsWith('{')) {
        // 设置 Alias
        const aliasPath = val.replace(/[{}]/g, '').replace(/\./g, '/');
        const targetId = variableMap[aliasPath];
        if (targetId) {
          v.setValueForMode(mode.modeId, { type: 'VARIABLE_ALIAS', id: targetId });
        }
      } else {
        // 设置原始值
        const type = v.resolvedType;
        const finalVal = type === 'COLOR' ? parseColor(val) : val;
        v.setValueForMode(mode.modeId, finalVal);
      }
    });
  } else {
    // 变量不存在，创建新变量
    let type = 'FLOAT';
    if (typeof value === 'string' && (value.startsWith('#') || isColorAlias(value))) {
      type = 'COLOR';
    } else if (typeof value === 'object' && !isAlias(value)) {
      // mode 对象中的值
      const firstVal = Object.values(value)[0];
      if (typeof firstVal === 'string' && firstVal.startsWith('#')) {
        type = 'COLOR';
      }
    } else if (typeof value === 'string' && isAlias(value)) {
      type = 'FLOAT'; 
    }

    v = figma.variables.createVariable(path, collection, type);
    
    // 设置值
    collection.modes.forEach(mode => {
      const val = resolveValue(value, mode.name);
      if (typeof val === 'string' && val.startsWith('{')) {
        // 设置 Alias
        const aliasPath = val.replace(/[{}]/g, '').replace(/\./g, '/');
        const targetId = variableMap[aliasPath];
        if (targetId) {
          v.setValueForMode(mode.modeId, { type: 'VARIABLE_ALIAS', id: targetId });
        }
      } else {
        // 设置原始值
        const finalVal = type === 'COLOR' ? parseColor(val) : val;
        v.setValueForMode(mode.modeId, finalVal);
      }
    });
  }

  variableMap[`${colName.toLowerCase()}/${path}`] = v.id;
  // 特例：primitive 的路径可能需要去掉层级前缀供 semantic 引用
  if (colName === 'Primitive') {
    variableMap[`primitive/${path}`] = v.id;
  } else if (colName === 'Semantic') {
    variableMap[`semantic/${path}`] = v.id;
  }
}

function resolveValue(value, modeName) {
  // modeName 来自 Figma mode 名称 ("Light" 或 "Dark")
  // 需要转换为 tokens.json 中的模式键 ("light" 或 "dark")
  const modeKey = modeName.toLowerCase();
  
  if (typeof value === 'object' && value !== null) {
    return value[modeKey] || value['light'] || Object.values(value)[0];
  }
  return value;
}

function isColor(val) {
  return typeof val === 'string' && val.startsWith('#');
}

function isAlias(val) {
  return typeof val === 'string' && val.startsWith('{');
}

function isColorAlias(val) {
  // 启发式判断：如果引用路径包含 .color. 则是颜色引用
  return typeof val === 'string' && val.includes('.color.');
}

function parseColor(hex) {
  hex = hex.replace('#', '');
  const r = parseInt(hex.substring(0, 2), 16) / 255;
  const g = parseInt(hex.substring(2, 4), 16) / 255;
  const b = parseInt(hex.substring(4, 6), 16) / 255;
  let a = 1;
  if (hex.length === 8) {
    a = parseInt(hex.substring(6, 8), 16) / 255;
  }
  return { r, g, b, a };
}
