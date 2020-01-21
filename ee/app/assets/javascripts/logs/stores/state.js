// import { defaultTimeWindow } from '../constants';
import {
  getDefaultTimeRange,
  defaultTimeWindows,
} from '~/vue_shared/components/date_time_picker/date_time_picker_lib';

export default () => {
  const timeWindows = defaultTimeWindows;
  const { start, end } = getDefaultTimeRange(defaultTimeWindows);

  return {
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
      start,
      end,
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
  };
};
