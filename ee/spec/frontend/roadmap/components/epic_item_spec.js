import Vue from 'vue';

import _ from 'lodash';

import epicItemComponent from 'ee/roadmap/components/epic_item.vue';

import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';

import { PRESET_TYPES } from 'ee/roadmap/constants';

import mountComponent from 'helpers/vue_mount_component_helper';
import { mockTimeframeInitialDate, mockEpic, mockGroupId } from 'ee_jest/roadmap/mock_data';

jest.mock('lodash/delay', () =>
  jest.fn(func => {
    // eslint-disable-next-line no-param-reassign
    func.delay = jest.fn();
    return func;
  }),
);

const mockTimeframeMonths = getTimeframeForMonthsView(mockTimeframeInitialDate);

const createComponent = ({
  presetType = PRESET_TYPES.MONTHS,
  epic = mockEpic,
  timeframe = mockTimeframeMonths,
  currentGroupId = mockGroupId,
}) => {
  const Component = Vue.extend(epicItemComponent);

  return mountComponent(Component, {
    presetType,
    epic,
    timeframe,
    currentGroupId,
  });
};

describe('EpicItemComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent({});
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('startDate', () => {
    it('returns Epic.startDate when start date is within range', () => {
      expect(vm.startDate).toBe(mockEpic.startDate);
    });

    it('returns Epic.originalStartDate when start date is out of range', () => {
      const mockStartDate = new Date(2018, 0, 1);
      const epic = Object.assign({}, mockEpic, {
        startDateOutOfRange: true,
        originalStartDate: mockStartDate,
      });
      vm = createComponent({ epic });

      expect(vm.startDate).toBe(mockStartDate);
    });
  });

  describe('endDate', () => {
    it('returns Epic.endDate when end date is within range', () => {
      expect(vm.endDate).toBe(mockEpic.endDate);
    });

    it('returns Epic.originalEndDate when end date is out of range', () => {
      const mockEndDate = new Date(2018, 0, 1);
      const epic = Object.assign({}, mockEpic, {
        endDateOutOfRange: true,
        originalEndDate: mockEndDate,
      });
      vm = createComponent({ epic });

      expect(vm.endDate).toBe(mockEndDate);
    });
  });

  describe('timeframeString', () => {
    it('returns timeframe string correctly when both start and end dates are defined', () => {
      expect(vm.timeframeString(mockEpic)).toBe('Jul 10, 2017 – Jun 2, 2018');
    });

    it('returns timeframe string correctly when only start date is defined', () => {
      const epic = Object.assign({}, mockEpic, {
        endDateUndefined: true,
      });
      vm = createComponent({ epic });

      expect(vm.timeframeString(epic)).toBe('Jul 10, 2017 – No end date');
    });

    it('returns timeframe string correctly when only end date is defined', () => {
      const epic = Object.assign({}, mockEpic, {
        startDateUndefined: true,
      });
      vm = createComponent({ epic });

      expect(vm.timeframeString(epic)).toBe('No start date – Jun 2, 2018');
    });

    it('returns timeframe string with hidden year for start date when both start and end dates are from same year', () => {
      const epic = Object.assign({}, mockEpic, {
        startDate: new Date(2018, 0, 1),
        endDate: new Date(2018, 3, 1),
      });
      vm = createComponent({ epic });

      expect(vm.timeframeString(epic)).toBe('Jan 1 – Apr 1, 2018');
    });
  });

  describe('methods', () => {
    describe('removeHighlight', () => {
      it('should call _.delay after 3 seconds with a callback function which would set `epic.newEpic` to false when it is true already', done => {
        vm.epic.newEpic = true;

        vm.removeHighlight();

        vm.$nextTick()
          .then(() => {
            expect(_.delay).toHaveBeenCalledWith(expect.any(Function), 3000);
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('template', () => {
    it('renders component container element class `epics-list-item`', () => {
      expect(vm.$el.classList.contains('epics-list-item')).toBeTruthy();
    });

    it('renders Epic item details element with class `epic-details-cell`', () => {
      expect(vm.$el.querySelector('.epic-details-cell')).not.toBeNull();
    });

    it('renders Epic timeline element with class `epic-timeline-cell`', () => {
      expect(vm.$el.querySelector('.epic-timeline-cell')).not.toBeNull();
    });
  });
});
