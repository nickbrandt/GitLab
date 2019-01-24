export default {
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
  state: '',
  created: '',
  author: null,
  initialTitleHtml: '',
  initialTitleText: '',
  initialDescriptionHtml: '',
  initialDescriptionText: '',

  todoExists: false,
  startDateSourcingMilestoneTitle: '',
  startDateIsFixed: false,
  startDateFixed: '',
  startDateFromMilestones: '',
  startDate: '',
  dueDateSourcingMilestoneTitle: '',
  dueDateIsFixed: '',
  dueDateFixed: '',
  dueDateFromMilestones: '',
  dueDate: '',
  labels: [],
  participants: [],
  subscribed: false,

  // UI status flags
  epicStatusChangeInProgress: false,
  epicDeleteInProgress: false,
};
