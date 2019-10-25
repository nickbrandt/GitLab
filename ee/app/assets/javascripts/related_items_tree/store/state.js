export default () => ({
  // Initial Data
  parentItem: {},
  epicsEndpoint: '',
  issuesEndpoint: '',

  children: {},
  childrenFlags: {},
  childrenCounts: {
    epics: {},
    issues: {},
  },

  // Add Item Form Data
  issuableType: null,
  itemInputValue: '',
  pendingReferences: [],
  itemAutoCompleteSources: {},

  // UI Flags
  itemsFetchInProgress: false,
  itemsFetchFailure: false,
  itemsFetchResultEmpty: false,
  itemAddInProgress: false,
  itemCreateInProgress: false,
  showAddItemForm: false,
  showCreateEpicForm: false,
  autoCompleteEpics: false,
  autoCompleteIssues: false,
  removeItemModalProps: {
    parentItem: {},
    item: {},
  },
});
