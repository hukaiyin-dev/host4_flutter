figma.showUI(__html__, { width: 320, height: 240 });

let variableMap = {};
let collections = {};
let _brokenVarCache = {};

figma.ui.onmessage = async (msg) => {
  if (msg.type === 'process-tokens') {
    try {
      variableMap = {};
      collections = {};
      const tokens = msg.data.tokens || msg.data;
      await processTokens(tokens);

      figma.ui.postMessage({ type: 'status', text: '⏳ 正在重新绑定组件变量...' });
      const count = await rebindAllNodes();
      figma.ui.postMessage({ type: 'status', text: '✅ 同步成功！已重新绑定 ' + count + ' 处变量引用' });
    } catch (err) {
      figma.ui.postMessage({ type: 'status', text: '❌ 错误: ' + err.message });
      console.error(err);
    }
  }
};

async function rebindAllNodes() {
  const localVars = await figma.variables.getLocalVariablesAsync();
  const nameToVar = {};
  const idToVar = {};
  for (const v of localVars) {
    nameToVar[v.name] = v;
    idToVar[v.id] = v;
  }

  // 第一步：收集所有断开的变量ID
  const brokenIds = new Set();
  for (let i = 0; i < figma.root.children.length; i++) {
    collectBrokenIds(figma.root.children[i], idToVar, brokenIds);
  }

  // 批量解析断开变量的名字
  _brokenVarCache = {};
  const brokenArr = Array.from(brokenIds);
  for (let i = 0; i < brokenArr.length; i++) {
    try {
      const v = await figma.variables.getVariableByIdAsync(brokenArr[i]);
      if (v) _brokenVarCache[brokenArr[i]] = v.name;
    } catch (e) {}
  }

  // 第二步：重新绑定
  let rebindCount = 0;
  for (let i = 0; i < figma.root.children.length; i++) {
    rebindCount += await walkAndRebind(figma.root.children[i], nameToVar, idToVar);
  }
  return rebindCount;
}

function collectBrokenIds(node, idToVar, result) {
  function check(binding) {
    if (binding && binding.type === 'VARIABLE_ALIAS' && !idToVar[binding.id]) {
      result.add(binding.id);
    }
  }
  if ('fills' in node && Array.isArray(node.fills)) {
    for (let i = 0; i < node.fills.length; i++) {
      const fill = node.fills[i];
      if (fill.boundVariables && fill.boundVariables.color) check(fill.boundVariables.color);
    }
  }
  if ('strokes' in node && Array.isArray(node.strokes)) {
    for (let i = 0; i < node.strokes.length; i++) {
      const stroke = node.strokes[i];
      if (stroke.boundVariables && stroke.boundVariables.color) check(stroke.boundVariables.color);
    }
  }
  if (node.boundVariables) {
    const keys = Object.keys(node.boundVariables);
    for (let i = 0; i < keys.length; i++) {
      const b = node.boundVariables[keys[i]];
      if (Array.isArray(b)) {
        for (let j = 0; j < b.length; j++) check(b[j]);
      } else {
        check(b);
      }
    }
  }
  if ('children' in node) {
    for (let i = 0; i < node.children.length; i++) {
      collectBrokenIds(node.children[i], idToVar, result);
    }
  }
}

async function walkAndRebind(node, nameToVar, idToVar) {
  let count = 0;

  function remap(binding) {
    if (binding && binding.type === 'VARIABLE_ALIAS' && !idToVar[binding.id]) {
      const varName = _brokenVarCache[binding.id];
      if (varName && nameToVar[varName]) {
        count++;
        return { type: 'VARIABLE_ALIAS', id: nameToVar[varName].id };
      }
    }
    return null; // null 表示不需要替换
  }

  // fills
  if ('fills' in node && Array.isArray(node.fills)) {
    let changed = false;
    const newFills = [];
    for (let i = 0; i < node.fills.length; i++) {
      const fill = node.fills[i];
      if (fill.boundVariables && fill.boundVariables.color) {
        const newB = remap(fill.boundVariables.color);
        if (newB) {
          changed = true;
          const newBoundVars = Object.assign({}, fill.boundVariables, { color: newB });
          const newFill = Object.assign({}, fill, { boundVariables: newBoundVars });
          newFills.push(newFill);
          continue;
        }
      }
      newFills.push(fill);
    }
    if (changed) {
      try { node.fills = newFills; } catch (e) {}
    }
  }

  // strokes
  if ('strokes' in node && Array.isArray(node.strokes)) {
    let changed = false;
    const newStrokes = [];
    for (let i = 0; i < node.strokes.length; i++) {
      const stroke = node.strokes[i];
      if (stroke.boundVariables && stroke.boundVariables.color) {
        const newB = remap(stroke.boundVariables.color);
        if (newB) {
          changed = true;
          const newBoundVars = Object.assign({}, stroke.boundVariables, { color: newB });
          const newStroke = Object.assign({}, stroke, { boundVariables: newBoundVars });
          newStrokes.push(newStroke);
          continue;
        }
      }
      newStrokes.push(stroke);
    }
    if (changed) {
      try { node.strokes = newStrokes; } catch (e) {}
    }
  }

  // 数值类 boundVariables
  if (node.boundVariables) {
    const numProps = ['opacity', 'cornerRadius', 'itemSpacing', 'paddingLeft', 'paddingRight', 'paddingTop', 'paddingBottom', 'strokeWeight'];
    for (let i = 0; i < numProps.length; i++) {
      const prop = numProps[i];
      const binding = node.boundVariables[prop];
      if (binding && binding.type === 'VARIABLE_ALIAS' && !idToVar[binding.id]) {
        const varName = _brokenVarCache[binding.id];
        if (varName && nameToVar[varName]) {
          try { node.setBoundVariable(prop, nameToVar[varName]); count++; } catch (e) {}
        }
      }
    }
  }

  // 递归子节点
  if ('children' in node) {
    for (let i = 0; i < node.children.length; i++) {
      count += await walkAndRebind(node.children[i], nameToVar, idToVar);
    }
  }

  return count;
}

async function processTokens(tokens) {
  const colNames = ['Primitive', 'Semantic', 'Component'];
  const localCollections = await figma.variables.getLocalVariableCollectionsAsync();
  
  for (const name of colNames) {
    let col = localCollections.find(c => c.name === name);
    if (!col) col = figma.variables.createVariableCollection(name);
    
    if (name === 'Semantic') {
      if (col.modes.length < 2) col.addMode('Dark');
      col.renameMode(col.modes[0].modeId, 'Light');
      col.renameMode(col.modes[1].modeId, 'Dark');
    } else {
      col.renameMode(col.modes[0].modeId, 'Value');
    }
    collections[name] = col;
  }

  const localVars = await figma.variables.getLocalVariablesAsync();
  const varCache = {};
  for (const v of localVars) varCache[v.variableCollectionId + ':' + v.name] = v;

  if (tokens.primitive) await traverseAndCreate(tokens.primitive, 'Primitive', [], tokens, varCache);
  if (tokens.semantic) await traverseAndCreate(tokens.semantic, 'Semantic', [], tokens, varCache);
  if (tokens.component) await traverseAndCreate(tokens.component, 'Component', [], tokens, varCache);
}

async function traverseAndCreate(node, colName, pathSegments, tokens, varCache, aliasPrefix) {
  aliasPrefix = aliasPrefix || null;
  const collection = collections[colName];

  for (const key in node) {
    const value = node[key];
    const currentPath = pathSegments.concat([key]);
    const fullPath = currentPath.join('/');

    let effectiveValue = value;
    if (aliasPrefix) effectiveValue = '{' + aliasPrefix + '.' + key + '}';

    if (isModeObject(effectiveValue)) {
      await createVariable(collection, fullPath, effectiveValue, colName, tokens, varCache, true);
    } else if (typeof effectiveValue === 'string' && effectiveValue.startsWith('{')) {
      const targetValue = resolveAliasTarget(effectiveValue, tokens);
      if (targetValue === undefined) {
        if (effectiveValue.startsWith('{asset.')) await createVariable(collection, fullPath, effectiveValue, colName, tokens, varCache, false);
        continue;
      } else if (typeof targetValue === 'object' && targetValue !== null && !isColor(targetValue) && !isModeObject(targetValue)) {
        const nextAliasPrefix = effectiveValue.replace(/[{}]/g, '');
        await traverseAndCreate(targetValue, colName, currentPath, tokens, varCache, nextAliasPrefix);
      } else {
        await createVariable(collection, fullPath, effectiveValue, colName, tokens, varCache, false);
      }
    } else if (typeof effectiveValue === 'object' && effectiveValue !== null && !isColor(effectiveValue) && !isModeObject(effectiveValue)) {
      await traverseAndCreate(effectiveValue, colName, currentPath, tokens, varCache, null);
    } else {
      await createVariable(collection, fullPath, effectiveValue, colName, tokens, varCache, false);
    }
  }
}

async function createVariable(collection, path, value, colName, tokens, varCache, forceModeMarker) {
  let v = varCache[collection.id + ':' + path];

  let type = 'FLOAT';
  const firstVal = typeof value === 'object' ? (value.light || value.dark || Object.values(value)[0]) : value;
  if (typeof firstVal === 'string' && (firstVal.startsWith('#') || firstVal.includes('.color.'))) type = 'COLOR';

  if (!v) {
    v = figma.variables.createVariable(path, collection, type);
    varCache[collection.id + ':' + path] = v;
  }

  let description = '';
  if (forceModeMarker) description += '[M]';
  if (typeof value === 'string' && value.startsWith('{asset.')) description += value;
  else if (typeof value === 'object' && value.light && typeof value.light === 'string' && value.light.startsWith('{asset.')) description += value.light;
  v.description = description;

  for (const mode of collection.modes) {
    const modeName = mode.name.toLowerCase();
    const rawVal = resolveValueForMode(value, modeName);
    
    if (typeof rawVal === 'string' && rawVal.startsWith('{')) {
      const aliasPath = rawVal.split(/[{}]/g).filter(Boolean)[0].split('.').join('/');
      const targetId = variableMap[aliasPath];
      if (targetId) v.setValueForMode(mode.modeId, { type: 'VARIABLE_ALIAS', id: targetId });
      else if (rawVal.startsWith('{asset.')) v.setValueForMode(mode.modeId, 0);
    } else if (rawVal !== undefined) {
      const finalVal = type === 'COLOR' ? (typeof rawVal === 'string' ? parseColor(rawVal) : { r: 0, g: 0, b: 0, a: 1 }) : (typeof rawVal === 'number' ? rawVal : 0);
      v.setValueForMode(mode.modeId, finalVal);
    }
  }
  variableMap[colName.toLowerCase() + '/' + path] = v.id;
}

function isModeObject(val) { return typeof val === 'object' && val !== null && (val.hasOwnProperty('light') || val.hasOwnProperty('dark')); }

function resolveAliasTarget(aliasStr, tokens) {
  const pathStr = aliasStr.replace(/[{}]/g, '');
  const parts = pathStr.split('.');
  let current = tokens;
  for (const part of parts) {
    if (current && typeof current === 'object' && current.hasOwnProperty(part)) current = current[part];
    else return undefined;
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
  if (hex.length === 3) hex = hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2];
  const r = parseInt(hex.substring(0, 2), 16) / 255;
  const g = parseInt(hex.substring(2, 4), 16) / 255;
  const b = parseInt(hex.substring(4, 6), 16) / 255;
  let a = 1;
  if (hex.length === 8) a = parseInt(hex.substring(6, 8), 16) / 255;
  return { r: r, g: g, b: b, a: a };
}
