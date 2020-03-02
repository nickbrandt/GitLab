import { timeRanges, defaultTimeRange } from '~/monitoring/constants';
import { convertToFixedRange } from '~/lib/utils/datetime_range';

export default () => ({
  /**
   * Full text search
   */
  search: '',

  /**
   * Time range (Show last)
   */
  timeRange: {
    options: timeRanges,
    // Selected time range, can be fixed or relative
    selected: defaultTimeRange,
    // Current time range, must be fixed
    current: convertToFixedRange(defaultTimeRange),
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
    pageInfo: {
      currentPage: 0,
      nextPage: 0,
      totalPages: 0,
      totalResults: 0,
    },
  },

  /**
   * Pods list information
   */
  pods: {
    options: [],
    current: null,
  },
});
