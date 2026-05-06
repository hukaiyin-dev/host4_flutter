figma.showUI(__html__, { width: 320, height: 280 });

figma.ui.onmessage = async (msg) => {
  if (msg.type === 'export-variables') {
    try {
      const tokens = await exportVariables();
      figma.ui.postMessage({ type: 'export-success', data: JSON.stringify(tokens, null, 2) });
    } catch (err) {
      figma.ui.postMessage({ type: 'export-error', message: err.message });
      console.error(err);
    }
  }
};

async function exportVariables() {
  const result = {
    schema: "1.0",
    primitive: {},
    semantic: {},
    component: {}
  };

  const collections = await figma.variables.getLocalVariableCollectionsAsync();
  const targetCollections = collections.filter(c => 
    ['Primitive', 'Semantic', 'Component'].includes(c.name)
  );

  const allVariables = await figma.variables.getLocalVariablesAsync();
  const variableIdMap = {};

  // 1. 建立变量 ID 到路径的映射，用于还原 Alias
  for (const v of allVariables) {
    const col = collections.find(c => c.id === v.variableCollectionId);
    if (col) {
      const colPrefix = col.name.toLowerCase();
      const dotPath = v.name.split('/').join('.');
      variableIdMap[v.id] = `{${colPrefix}.${dotPath}}`;
    }
  }

  // 2. 遍历每个集合构建 JSON
  for (const col of targetCollections) {
    const colKey = col.name.toLowerCase();
    const variables = allVariables.filter(v => v.variableCollectionId === col.id);

    for (const v of variables) {
      const pathSegments = v.name.split('/');
      let currentLevel = result[colKey];
      const description = v.description || "";

      // 检查元数据标记
      const forceModes = description.includes('[M]');
      
      // 处理多模式 (仅 Semantic 支持模式分支)
      if (col.name === 'Semantic') {
        const modeValues = col.modes.map(mode => {
          let val = processValue(v.valuesByMode[mode.modeId], variableIdMap, v.resolvedType);
          // 尝试从描述中还原 asset 引用 (清理标记后再检查)
          const assetPath = description.replace('[M]', '');
          if (val === 0 && assetPath.startsWith('{asset.')) {
            val = assetPath;
          }
          return val;
        });

        const firstVal = modeValues[0];
        const allSame = modeValues.every(val => val === firstVal);

        // 仅当没有 [M] 标记且值全相同时才坍缩
        if (allSame && !forceModes) {
          buildNestedObject(currentLevel, pathSegments, firstVal);
        } else {
          const valueObj = {};
          for (let i = 0; i < col.modes.length; i++) {
            const modeKey = col.modes[i].name.toLowerCase();
            valueObj[modeKey] = modeValues[i];
          }
          buildNestedObject(currentLevel, pathSegments, valueObj);
        }
      } else {
        const firstModeValue = v.valuesByMode[col.modes[0].modeId];
        let processedVal = processValue(firstModeValue, variableIdMap, v.resolvedType);
        
        // 尝试从描述中还原 asset 引用
        if (processedVal === 0 && description.startsWith('{asset.')) {
          processedVal = description;
        }
        
        buildNestedObject(currentLevel, pathSegments, processedVal);
      }
    }
  }

  return result;
}

function processValue(value, idMap, type) {
  if (value && typeof value === 'object' && value.type === 'VARIABLE_ALIAS') {
    return idMap[value.id] || 0;
  }
  if (type === 'COLOR' && value && typeof value === 'object') {
    return rgbaToHex(value);
  }
  if (typeof value === 'number') {
    return Math.round(value * 1000000) / 1000000;
  }
  return value;
}

function buildNestedObject(obj, path, value) {
  for (let i = 0; i < path.length - 1; i++) {
    const part = path[i];
    if (!obj[part]) obj[part] = {};
    obj = obj[part];
  }
  obj[path[path.length - 1]] = value;
}

function rgbaToHex({ r, g, b, a }) {
  const hex = (v) => Math.round(v * 255).toString(16).toUpperCase().padStart(2, '0');
  const res = `#${hex(r)}${hex(g)}${hex(b)}`;
  return a < 1 ? res + hex(a) : res;
}
