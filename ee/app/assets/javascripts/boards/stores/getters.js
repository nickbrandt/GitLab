import gettersCE from '~/boards/stores/getters';

export default {
  ...gettersCE,

  getIssues: (state, getters) => listId => {
    const listIssueIds = state.issuesByListId[listId] || [];

    return listIssueIds.map(id => getters.getIssueById(id));
  },
  getIssuesByEpic: (state, getters) => (listId, epicId) => {
    return getters.getIssues(listId).filter(issue => issue.epic && issue.epic.id === epicId);
  },

  unassignedIssues: (state, getters) => listId => {
    return getters.getIssues(listId).filter(i => i.epic === null);
  },
};
