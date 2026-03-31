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
      // 使用 split 和 join 确保所有段（包括数字段 .0）都被保留
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

      // 处理多模式 (仅 Semantic 支持模式分支)
      if (col.name === 'Semantic') {
        const modeValues = col.modes.map(mode => {
          let val = processValue(v.valuesByMode[mode.modeId], variableIdMap, v.resolvedType);
          // 尝试从描述中还原 asset 引用
          if (val === 0 && v.description && v.description.startsWith('{asset.')) {
            val = v.description;
          }
          return val;
        });

        // 自动坍缩逻辑：如果所有模式的值完全一致，则直接返回标量
        const firstVal = modeValues[0];
        const allSame = modeValues.every(val => val === firstVal);

        if (allSame) {
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
        // Primitive 和 Component 使用第一个模式的值 (单模式)
        const firstModeValue = v.valuesByMode[col.modes[0].modeId];
        let processedVal = processValue(firstModeValue, variableIdMap, v.resolvedType);
        
        // 尝试从描述中还原 asset 引用
        if (processedVal === 0 && v.description && v.description.startsWith('{asset.')) {
          processedVal = v.description;
        }
        
        buildNestedObject(currentLevel, pathSegments, processedVal);
      }
    }
  }

  return result;
}

function processValue(value, idMap, type) {
  // 处理 Alias
  if (value && typeof value === 'object' && value.type === 'VARIABLE_ALIAS') {
    const aliasStr = idMap[value.id];
    return aliasStr || 0;
  }

  // 处理颜色
  if (type === 'COLOR' && value && typeof value === 'object') {
    return rgbaToHex(value);
  }

  // 处理数字：解决 JS 浮点数精度噪声 (如 0.119999... -> 0.12)
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
  const toHex = (v) => {
    const hex = Math.round(v * 255).toString(16).toUpperCase();
    return hex.length === 1 ? '0' + hex : hex;
  };

  const hexR = toHex(r);
  const hexG = toHex(g);
  const hexB = toHex(b);
  const hexA = a < 1 ? toHex(a) : '';

  return `#${hexR}${hexG}${hexB}${hexA}`;
}
