export default () => ({
  /**
   * Current project path
   */
  projectPath: '',

  /**
   * Full text search
   */
  search: '',

  /**
   * True if log source is elasticsearch
   */
  enableAdvancedQuerying: false,

  /**
   * Environments list information
   */
  environments: {
    options: [],
    isLoading: false,
    current: null,
  },

  /**
   * Logs including trace
   */
  logs: {
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
