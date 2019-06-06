import { ChildType, ActionType, PathIdSeparator } from '../constants';

export const autoCompleteSources = () => gl.GfmAutoComplete && gl.GfmAutoComplete.dataSources;

export const directChildren = state => state.children[state.parentItem.reference] || [];

export const anyParentHasChildren = (state, getters) =>
  getters.directChildren.some(item => item.hasChildren || item.hasIssues);

export const headerItems = (state, getters) => {
  const children = getters.directChildren || [];
  let totalEpics = 0;
  let totalIssues = 0;

  children.forEach(item => {
    if (item.type === ChildType.Epic) {
      totalEpics += 1;
    } else {
      totalIssues += 1;
    }
  });

  return [
    {
      iconName: 'epic',
      count: totalEpics,
      qaClass: 'qa-add-epics-button',
      type: ChildType.Epic,
    },
    {
      iconName: 'issues',
      count: totalIssues,
      qaClass: 'qa-add-issues-button',
      type: ChildType.Issue,
    },
  ];
};

export const epicsBeginAtIndex = (state, getters) =>
  getters.directChildren.findIndex(item => item.type === ChildType.Epic);

export const itemAutoCompleteSources = (state, getters) => {
  if (state.actionType === ActionType.Epic) {
    return state.autoCompleteEpics ? getters.autoCompleteSources : {};
  }
  return state.autoCompleteIssues ? getters.autoCompleteSources : {};
};

export const itemPathIdSeparator = state =>
  state.actionType === ActionType.Epic ? PathIdSeparator.Epic : PathIdSeparator.Issue;

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
