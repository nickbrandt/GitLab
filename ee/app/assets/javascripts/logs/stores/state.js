import { defaultTimeWindow, timeWindows } from '../constants';

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
   * Time range (Show last)
   */
  timeWindow: {
    options: { ...timeWindows },
    current: defaultTimeWindow,
  },

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
