export default () => ({
  milestonesPath: '',
  labelsPath: '',
  milestones: {
    isLoading: false,
    data: [],
  },
  labels: {
    isLoading: false,
    data: [],
  },
  authors: {
    isLoading: false,
    data: [],
  },
  assignees: {
    isLoading: false,
    data: [],
  },
  initialTokens: {
    selectedMilestone: null,
    selectedAuthor: null,
    selectedAssignees: [],
    selectedLabels: [],
  },
});
