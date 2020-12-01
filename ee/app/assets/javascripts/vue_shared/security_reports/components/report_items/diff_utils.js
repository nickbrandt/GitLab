/**
 * Use the function `createDiffData` to create diff lines for rendering
 * diffs
 */

import { diffChars } from 'diff';

export function splitAction(action) {
  const splitValues = action.value.split('\n');
  const res = [];
  splitValues.forEach((splitValue) => {
    res.push({
      added: action.added,
      removed: action.removed,
      value: splitValue,
    });
  });
  return res;
}

export function createDistinctLines(type, startIdx, actions, lineKey) {
  const res = [];
  let currLineNo = startIdx;
  let currLine = null;
  const newLine = () => {
    if (currLine !== null) {
      res.push(currLine);
    }
    currLineNo += 1;
    currLine = { type, actions: [] };
    currLine[lineKey] = currLineNo;
  };
  newLine();

  actions.forEach((action) => {
    const splitActions = splitAction(action);
    currLine.actions.push(splitActions[0]);
    splitActions.slice(1).forEach((sAction) => {
      newLine();
      currLine.actions.push(sAction);
    });
  });
  res.push(currLine);

  return res;
}

export function splitLinesInline(lines) {
  const res = [];
  lines.forEach((line, idx) => {
    const removed = [];
    const added = [];
    const normal = [];

    line.actions.forEach((action) => {
      if (action.removed) {
        removed.push(action);
      } else if (action.added) {
        added.push(action);
      } else {
        removed.push(action);
        added.push(action);
        normal.push(action);
      }
    });
    if (normal.length === 1 && removed.length === 1 && added.length === 1) {
      res.push({ type: 'normal', old_line: idx + 1, actions: normal });
      return;
    }

    if (removed.length > 0) {
      res.push(...createDistinctLines('removed', idx, removed, 'old_line'));
    }
    if (added.length > 0) {
      res.push(...createDistinctLines('added', idx, added, 'new_line'));
    }
  });
  return res;
}

export function groupActionsByLines(actions) {
  const lines = [];
  let currLine = { actions: [] };

  while (actions.length > 0) {
    const action = actions.shift();
    if (action.value !== '') {
      const splitActions = splitAction(action);
      currLine.actions.push(splitActions[0]);
      if (splitActions.length > 1) {
        lines.push(currLine);
        currLine = { actions: [] };
        splitActions.slice(1).forEach((x) => actions.unshift(x));
      }
    }
  }
  lines.push(currLine);
  return lines;
}

/**
 * Create an array of line objects of the form
 *   {
 *     type: normal | added | removed,
 *     actions: [], // array of action objects (see below)
 *     new_line: undefined or number,
 *     old_line: undefined or number,
 *   }
 *
 * Actions objects have the form
 *
 *   {
 *     added: true | false,
 *     removed: true | false,
 *     value: string
 *   }
 */
export function createDiffData(before, after) {
  const opts = {
    ignoreWhitespace: false,
    newlineIsToken: true,
  };
  const actions = diffChars(before, after, opts);
  const lines = groupActionsByLines(actions);
  return splitLinesInline(lines);
}
