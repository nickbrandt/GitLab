export default () => ({
  milestonesEndpoint: '',
  labelsEndpoint: '',
  milestones: {
    isLoading: false,
    data: [],
    selected: null,
  },
  labels: {
    isLoading: false,
    data: [],
    selected: [],
  },
  authors: {
    isLoading: false,
    data: [],
    selected: null,
  },
  assignees: {
    isLoading: false,
    data: [],
    selected: [],
  },
});
