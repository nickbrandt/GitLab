import { shallowMount } from '@vue/test-utils';
import RotationsAssignee from 'ee/oncall_schedules/components/rotations/components/rotation_assignee.vue';
import DaysScheduleShift from 'ee/oncall_schedules/components/schedule/components/shifts/components/days_schedule_shift.vue';
import { PRESET_TYPES, DAYS_IN_WEEK } from 'ee/oncall_schedules/constants';
import { nDaysAfter } from '~/lib/utils/datetime_utility';

const shift = {
  participant: {
    id: '1',
    user: {
      username: 'nora.schaden',
    },
  },
  startsAt: '2021-01-15T00:04:56.333Z',
  endsAt: '2021-01-15T04:22:56.333Z',
};

const CELL_WIDTH = 50;
const timeframeItem = new Date(2021, 0, 15);
const timeframe = [timeframeItem, nDaysAfter(timeframeItem, DAYS_IN_WEEK)];

describe('ee/oncall_schedules/components/schedule/components/shifts/components/days_schedule_shift.vue', () => {
  let wrapper;

  function createComponent({ props = {} } = {}) {
    wrapper = shallowMount(DaysScheduleShift, {
      propsData: {
        shift,
        shiftIndex: 0,
        timeframeItem,
        timeframe,
        presetType: PRESET_TYPES.WEEKS,
        timelineWidth: CELL_WIDTH,
        ...props,
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findRotationAssignee = () => wrapper.findComponent(RotationsAssignee);

  describe('shift overlaps inside the current time-frame', () => {
    it('should render a rotation assignee child component', () => {
      expect(findRotationAssignee().exists()).toBe(true);
    });
  });
});
