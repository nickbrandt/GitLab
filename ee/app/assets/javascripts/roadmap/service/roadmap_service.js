import axios from '~/lib/utils/axios_utils';

import { getEpicsPathForPreset } from '../utils/roadmap_utils';

export default class RoadmapService {
  constructor({ basePath, epicsState, filterQueryString, initialEpicsPath }) {
    this.basePath = basePath;
    this.epicsState = epicsState;
    this.filterQueryString = filterQueryString;
    this.initialEpicsPath = initialEpicsPath;
  }

  getEpics() {
    return axios.get(this.initialEpicsPath);
  }

  getEpicsForTimeframe(presetType, timeframe) {
    const epicsPath = getEpicsPathForPreset({
      basePath: this.basePath,
      epicsState: this.epicsState,
      filterQueryString: this.filterQueryString,
      presetType,
      timeframe,
    });

    return axios.get(epicsPath);
  }
}
