export default () => ({
  // API Paths to Send/Receive Data
  endpoint: '',
  updateEndpoint: '',

  epicLinksEndpoint: '',
  issueLinksEndpoint: '',
  groupPath: '',
  markdownPreviewPath: '',
  labelsPath: '',
  todoPath: '',
  todoDeletePath: '',
  toggleSubscriptionPath: '',

  // URLs to use with links
  epicsWebUrl: '',
  labelsWebUrl: '',
  markdownDocsPath: '',

  // Flags
  canUpdate: false,
  canDestroy: false,
  canAdmin: false,
  subepicsSupported: false,

  // Epic Information
  epicId: 0,
  namespace: '#',
  state: '',
  created: '',
  author: null,
  initialTitleHtml: '',
  initialTitleText: '',
  initialDescriptionHtml: '',
  initialDescriptionText: '',

  todoExists: false,
  startDateSourcingMilestoneTitle: '',
  startDateSourcingMilestoneDates: {
    startDate: '',
    dueDate: '',
  },
  startDateIsFixed: false,
  startDateFixed: '',
  startDateFromMilestones: '',
  startDate: '',
  dueDateSourcingMilestoneTitle: '',
  dueDateSourcingMilestoneDates: {
    startDate: '',
    dueDate: '',
  },
  dueDateIsFixed: '',
  dueDateFixed: '',
  dueDateFromMilestones: '',
  dueDate: '',
  labels: [],
  parent: null,
  participants: [],
  subscribed: false,

  // UI status flags
  epicStatusChangeInProgress: false,
  epicDeleteInProgress: false,
  epicTodoToggleInProgress: false,
  epicStartDateSaveInProgress: false,
  epicDueDateSaveInProgress: false,
  sidebarCollapsed: false,
});
