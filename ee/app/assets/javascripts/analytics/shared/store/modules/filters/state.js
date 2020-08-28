export default () => ({
  milestonesEndpoint: '',
  labelsEndpoint: '',
  groupEndpoint: '',
  milestones: {
    isLoading: false,
    errorCode: null,
    data: [],
    selected: null,
  },
  labels: {
    isLoading: false,
    errorCode: null,
    data: [],
    selected: [],
  },
  authors: {
    isLoading: false,
    errorCode: null,
    data: [],
    selected: null,
  },
  assignees: {
    isLoading: false,
    errorCode: null,
    data: [],
    selected: [],
  },
});
