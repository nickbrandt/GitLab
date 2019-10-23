export default () => ({
  /**
   * Environments list information
   */
  environments: {
    options: [],
    isLoading: false,
  },

  /**
   * Logs including trace
   */
  logs: {
    endpoint: null,
    lines: [],
    isLoading: false,
    isComplete: true,
  },

  /**
   * Pods list information
   */
  pods: {
    options: [],
    current: null,
  },
});
