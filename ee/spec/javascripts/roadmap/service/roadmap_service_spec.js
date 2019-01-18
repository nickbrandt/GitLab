import axios from '~/lib/utils/axios_utils';

import RoadmapService from 'ee/roadmap/service/roadmap_service';
import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';

import { PRESET_TYPES } from 'ee/roadmap/constants';
import { basePath, epicsPath, mockTimeframeInitialDate } from '../mock_data';

const mockTimeframeMonths = getTimeframeForMonthsView(mockTimeframeInitialDate);

describe('RoadmapService', () => {
  let service;

  beforeEach(() => {
    service = new RoadmapService({
      initialEpicsPath: epicsPath,
      epicsState: 'all',
      filterQueryString: '',
      basePath,
    });
  });

  describe('getEpics', () => {
    it('returns axios instance for Epics path', () => {
      spyOn(axios, 'get').and.stub();
      service.getEpics();

      expect(axios.get).toHaveBeenCalledWith(
        '/groups/gitlab-org/-/epics.json?start_date=2017-11-1&end_date=2018-4-30',
      );
    });
  });

  describe('getEpicsForTimeframe', () => {
    it('calls `getEpicsPathForPreset` to construct epics path', () => {
      const getEpicsPathSpy = spyOnDependency(RoadmapService, 'getEpicsPathForPreset');
      spyOn(axios, 'get').and.stub();

      const presetType = PRESET_TYPES.MONTHS;

      service.getEpicsForTimeframe(presetType, mockTimeframeMonths);

      expect(getEpicsPathSpy).toHaveBeenCalledWith(
        jasmine.objectContaining({
          timeframe: mockTimeframeMonths,
          epicsState: 'all',
          filterQueryString: '',
          basePath,
          presetType,
        }),
      );
    });
  });
});
