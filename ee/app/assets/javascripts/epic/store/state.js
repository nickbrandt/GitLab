export default () => ({
  // API Paths to Send/Receive Data
  endpoint: '',
  updateEndpoint: '',

  groupPath: '',
  markdownPreviewPath: '',
  labelsPath: '',
  todoPath: '',
  todoDeletePath: '',

  // URLs to use with links
  epicsWebUrl: '',
  labelsWebUrl: '',
  markdownDocsPath: '',

  // Flags
  canUpdate: false,
  canDestroy: false,
  canAdmin: false,

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
  lockVersion: 0,

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
  ancestors: [],
  participants: [],
  subscribed: false,

  // Create Epic Props
  newEpicTitle: '',

  // UI status flags
  epicStatusChangeInProgress: false,
  epicDeleteInProgress: false,
  epicTodoToggleInProgress: false,
  epicStartDateSaveInProgress: false,
  epicDueDateSaveInProgress: false,
  epicSubscriptionToggleInProgress: false,
  epicCreateInProgress: false,
  sidebarCollapsed: false,
});
