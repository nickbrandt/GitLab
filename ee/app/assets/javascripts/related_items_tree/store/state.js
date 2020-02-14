export default () => ({
  // Initial Data
  parentItem: {},
  epicsEndpoint: '',
  issuesEndpoint: '',
  projectsEndpoint: null,
  userSignedIn: false,

  children: {},
  childrenFlags: {},
  epicsCount: 0,
  issuesCount: 0,
  descendantCounts: {
    openedEpics: 0,
    closedEpics: 0,
    openedIssues: 0,
    closedIssues: 0,
  },

  // Add Item Form Data
  issuableType: null,
  itemInputValue: '',
  pendingReferences: [],
  itemAutoCompleteSources: {},
  itemAddFailureType: null,
  itemAddFailureMessage: '',

  // UI Flags
  itemsFetchInProgress: false,
  itemsFetchFailure: false,
  itemsFetchResultEmpty: false,
  itemAddInProgress: false,
  itemAddFailure: false,
  itemCreateInProgress: false,
  showAddItemForm: false,
  showCreateEpicForm: false,
  autoCompleteEpics: false,
  autoCompleteIssues: false,
  allowSubEpics: false,
  removeItemModalProps: {
    parentItem: {},
    item: {},
  },

  projects: [],
});
