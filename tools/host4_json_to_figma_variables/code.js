figma.showUI(__html__, { width: 320, height: 240 });

let variableMap = {}; 
let collections = {}; 

figma.ui.onmessage = async (msg) => {
  if (msg.type === 'process-tokens') {
    try {
      variableMap = {};
      collections = {};
      
      const tokens = msg.data;
      
      // 检查输入数据结构，兼容误传
      const actualTokens = tokens.tokens || tokens;
      
      await processTokens(actualTokens);
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
    
    // 模式初始化逻辑
    if (name === 'Semantic') {
      if (col.modes.length < 2) {
        col.addMode('Dark');
      }
      col.renameMode(col.modes[0].modeId, 'Light');
      col.renameMode(col.modes[1].modeId, 'Dark');
    } else {
      col.renameMode(col.modes[0].modeId, 'Value');
    }
    collections[name] = col;
  }

  const localVars = await figma.variables.getLocalVariablesAsync();
  const varCache = {};
  for (const v of localVars) {
    varCache[`${v.variableCollectionId}:${v.name}`] = v;
  }

  // 1. Primitive 层
  if (tokens.primitive) {
    await traverseAndCreate(tokens.primitive, 'Primitive', [], tokens, varCache);
  }

  // 2. Semantic 层
  if (tokens.semantic) {
    await traverseAndCreate(tokens.semantic, 'Semantic', [], tokens, varCache);
  }

  // 3. Component 层
  if (tokens.component) {
    await traverseAndCreate(tokens.component, 'Component', [], tokens, varCache);
  }
}

async function traverseAndCreate(node, colName, pathSegments, tokens, varCache, aliasPrefix = null) {
  const collection = collections[colName];

  for (const key in node) {
    const value = node[key];
    const currentPath = [...pathSegments, key];
    const fullPath = currentPath.join('/');

    let effectiveValue = value;
    if (aliasPrefix) {
      effectiveValue = `{${aliasPrefix}.${key}}`;
    }

    if (isModeObject(effectiveValue)) {
      await createVariable(collection, fullPath, effectiveValue, colName, tokens, varCache);
    } else if (typeof effectiveValue === 'string' && effectiveValue.startsWith('{')) {
      const targetValue = resolveAliasTarget(effectiveValue, tokens);

      if (targetValue === undefined) {
        if (effectiveValue.startsWith('{asset.')) {
          await createVariable(collection, fullPath, 0, colName, tokens, varCache);
        }
        continue;
      } else if (typeof targetValue === 'object' && targetValue !== null && !isColor(targetValue) && !isModeObject(targetValue)) {
        const nextAliasPrefix = effectiveValue.replace(/[{}]/g, '');
        await traverseAndCreate(targetValue, colName, currentPath, tokens, varCache, nextAliasPrefix);
      } else {
        await createVariable(collection, fullPath, effectiveValue, colName, tokens, varCache);
      }
    } else if (typeof effectiveValue === 'object' && effectiveValue !== null && !isColor(effectiveValue) && !isModeObject(effectiveValue)) {
      await traverseAndCreate(effectiveValue, colName, currentPath, tokens, varCache, null);
    } else {
      await createVariable(collection, fullPath, effectiveValue, colName, tokens, varCache);
    }
  }
}

async function createVariable(collection, path, value, colName, tokens, varCache) {
  let v = varCache[`${collection.id}:${path}`];

  let type = 'FLOAT';
  const firstVal = typeof value === 'object' ? (value.light || value.dark || Object.values(value)[0]) : value;
  
  if (typeof firstVal === 'string') {
    if (firstVal.startsWith('#') || firstVal.includes('.color.')) {
      type = 'COLOR';
    }
  }

  if (!v) {
    v = figma.variables.createVariable(path, collection, type);
    varCache[`${collection.id}:${path}`] = v;
  }

  // 如果是 asset 引用，将其原始路径存入描述，方便反向导出还原
  if (typeof value === 'string' && value.startsWith('{asset.')) {
    v.description = value;
  } else if (typeof value === 'object' && value.light && typeof value.light === 'string' && value.light.startsWith('{asset.')) {
    v.description = value.light;
  }

  for (const mode of collection.modes) {
    const modeName = mode.name.toLowerCase();
    const rawVal = resolveValueForMode(value, modeName);
    
    if (typeof rawVal === 'string' && rawVal.startsWith('{')) {
      const aliasPath = rawVal.replace(/[{}]/g, '').replace(/\./g, '/');
      const targetId = variableMap[aliasPath];
      if (targetId) {
        v.setValueForMode(mode.modeId, { type: 'VARIABLE_ALIAS', id: targetId });
      } else if (rawVal.startsWith('{asset.')) {
        v.setValueForMode(mode.modeId, 0);
      }
    } else if (rawVal !== undefined) {
      const finalVal = type === 'COLOR' 
        ? (typeof rawVal === 'string' ? parseColor(rawVal) : { r: 0, g: 0, b: 0, a: 1 }) 
        : (typeof rawVal === 'number' ? rawVal : 0);
      v.setValueForMode(mode.modeId, finalVal);
    }
  }

  variableMap[`${colName.toLowerCase()}/${path}`] = v.id;
}

function isModeObject(val) {
  return typeof val === 'object' && val !== null && (val.hasOwnProperty('light') || val.hasOwnProperty('dark'));
}

function resolveAliasTarget(aliasStr, tokens) {
  const pathStr = aliasStr.replace(/[{}]/g, ''); 
  const parts = pathStr.split('.'); 
  
  let current = tokens;
  for (const part of parts) {
    if (current && typeof current === 'object' && current.hasOwnProperty(part)) {
      current = current[part];
    } else {
      return undefined;
    }
  }
  return current;
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

function parseColor(hex) {
  hex = hex.replace('#', '');
  if (hex.length === 3) {
    hex = hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2];
  }
  const r = parseInt(hex.substring(0, 2), 16) / 255;
  const g = parseInt(hex.substring(2, 4), 16) / 255;
  const b = parseInt(hex.substring(4, 6), 16) / 255;
  let a = 1;
  if (hex.length === 8) a = parseInt(hex.substring(6, 8), 16) / 255;
  return { r, g, b, a };
}
