export default () => ({
  // Initial Data
  parentItem: {},
  epicsEndpoint: '',
  issuesEndpoint: '',

  children: {},
  childrenFlags: {},

  // Add Item Form Data
  actionType: '',
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
  showCreateItemForm: false,
  autoCompleteEpics: false,
  autoCompleteIssues: false,
  removeItemModalProps: {
    parentItem: {},
    item: {},
  },
});
