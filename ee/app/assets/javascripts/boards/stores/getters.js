import gettersCE from '~/boards/stores/getters';

export default {
  ...gettersCE,

  getIssues: state => listId => {
    return state.issuesByListId[listId] || [];
  },
  getIssuesByEpic: (state, getters) => (listId, epicId) => {
    return getters.getIssues(listId).filter(issue => issue.epic && issue.epic.id === epicId);
  },

  unassignedIssues: (state, getters) => listId => {
    return getters.getIssues(listId).filter(i => i.epic === null);
  },
};
