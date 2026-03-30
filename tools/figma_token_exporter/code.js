figma.showUI(__html__, { width: 320, height: 240 });

const variableMap = {}; 
const collections = {}; 

figma.ui.onmessage = async (msg) => {
  if (msg.type === 'process-tokens') {
    try {
      await processTokens(msg.data);
      figma.ui.postMessage({ type: 'status', text: '✅ 同步成功!' });
    } catch (err) {
      figma.ui.postMessage({ type: 'status', text: '❌ 错误: ' + err.message });
      console.error(err);
    }
  }
};

async function processTokens(tokens) {
  const colNames = ['Primitive', 'Semantic', 'Component'];
  const localCollections = await figma.variables.getLocalVariableCollectionsAsync();
  
  for (const name of colNames) {
    let col = localCollections.find(c => c.name === name);
    if (!col) {
      col = figma.variables.createVariableCollection(name);
    }
    // 强制建立 Light/Dark 模式
    if (name !== 'Primitive' && col.modes.length < 2) {
      col.addMode('Dark');
      col.renameMode(col.modes[0].modeId, 'Light');
    }
    collections[name] = col;
  }

  // 1. Primitive 层 (不含 Mode，直接创建)
  if (tokens.primitive) {
    await traverseAndCreate(tokens.primitive, 'Primitive', []);
  }

  // 2. Semantic 层 (支持 Mode)
  if (tokens.semantic) {
    await traverseAndCreate(tokens.semantic, 'Semantic', []);
  }

  // 3. Component 层 (支持 Mode)
  if (tokens.component) {
    await traverseAndCreate(tokens.component, 'Component', []);
  }
}

async function traverseAndCreate(node, colName, pathSegments) {
  const collection = collections[colName];

  for (const key in node) {
    const value = node[key];
    const currentPath = [...pathSegments, key];
    const fullPath = currentPath.join('/');

    // 修复关键：判断是否是 Mode 对象 (即包含 light/dark 键)
    if (isModeObject(value)) {
      await createVariable(collection, fullPath, value, colName);
    } else if (typeof value === 'string' && value.startsWith('{')) {
      // 这是一个 alias，检查是否指向对象结构
      // 如果 alias 指向 typography、effect 这样的对象结构，不创建变量
      if (!isAliasToObjectStructure(value)) {
        // 只为指向原始值（颜色、数字）的 alias 创建变量
        await createVariable(collection, fullPath, value, colName);
      }
      // 否则跳过，让设计师手动处理复杂对象
    } else if (typeof value === 'object' && value !== null && !isColor(value)) {
      // 递归处理子对象
      await traverseAndCreate(value, colName, currentPath);
    } else {
      // 基础值（颜色或数字）
      await createVariable(collection, fullPath, value, colName);
    }
  }
}

async function createVariable(collection, path, value, colName) {
  const localVars = await figma.variables.getLocalVariablesAsync();
  let v = localVars.find(varItem => varItem.name === path && varItem.variableCollectionId === collection.id);

  // 类型识别
  let type = 'FLOAT';
  const firstVal = typeof value === 'object' ? Object.values(value)[0] : value;
  if (typeof firstVal === 'string' && (firstVal.startsWith('#') || firstVal.includes('.color.'))) {
    type = 'COLOR';
  } else if (typeof firstVal === 'string' && (firstVal.includes('.typography.') || firstVal.includes('.style.'))) {
     // 文本样式在 Variables 中通常不支持，但如果是引用数值
     type = 'FLOAT';
  }

  if (!v) {
    v = figma.variables.createVariable(path, collection, type);
  }

  // 模式赋值逻辑
  for (const mode of collection.modes) {
    const modeName = mode.name.toLowerCase();
    const rawVal = resolveValueForMode(value, modeName);
    
    if (typeof rawVal === 'string' && rawVal.startsWith('{')) {
      // 处理 Alias
      const aliasPath = rawVal.replace(/[{}]/g, '').replace(/\./g, '/');
      const targetId = variableMap[aliasPath];
      if (targetId) {
        v.setValueForMode(mode.modeId, { type: 'VARIABLE_ALIAS', id: targetId });
      }
    } else if (rawVal !== undefined) {
      // 处理原始值
      const finalVal = type === 'COLOR' ? parseColor(rawVal) : rawVal;
      v.setValueForMode(mode.modeId, finalVal);
    }
  }

  // 记录到 Map 供后续引用
  variableMap[`${colName.toLowerCase()}/${path}`] = v.id;
}

function isModeObject(val) {
  return typeof val === 'object' && val !== null && (val.hasOwnProperty('light') || val.hasOwnProperty('dark'));
}

function isAliasToObjectStructure(aliasStr) {
  // 检查 alias 是否指向复杂对象结构
  // typography、effect、size 等通常是对象结构，不应作为 Variables 引用
  const objectPaths = ['.typography.', '.effect.', '.size.'];
  return objectPaths.some(path => aliasStr.includes(path));
}

function resolveValueForMode(value, mode) {
  if (typeof value === 'object' && value !== null) {
    if (value.hasOwnProperty(mode)) return value[mode];
    if (value.hasOwnProperty('light')) return value['light'];
    return Object.values(value)[0];
  }
  return value;
}

function isColor(val) { return typeof val === 'string' && val.startsWith('#'); }
function isAlias(val) { return typeof val === 'string' && val.startsWith('{'); }

function parseColor(hex) {
  hex = hex.replace('#', '');
  const r = parseInt(hex.substring(0, 2), 16) / 255;
  const g = parseInt(hex.substring(2, 4), 16) / 255;
  const b = parseInt(hex.substring(4, 6), 16) / 255;
  let a = 1;
  if (hex.length === 8) a = parseInt(hex.substring(6, 8), 16) / 255;
  return { r, g, b, a };
}
