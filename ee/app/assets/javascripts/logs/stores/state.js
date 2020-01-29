import { defaultTimeWindow, timeWindows } from '../constants';

export default () => ({
  /**
   * Full text search
   */
  search: '',

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
