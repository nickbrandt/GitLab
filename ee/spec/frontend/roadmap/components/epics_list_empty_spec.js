import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import EpicsListEmpty from 'ee/roadmap/components/epics_list_empty.vue';
import { mockTimeframeInitialDate, mockSvgPath } from 'ee_jest/roadmap/mock_data';
import { TEST_HOST } from 'helpers/test_constants';
import { PRESET_TYPES } from 'ee/roadmap/constants';
import { getTimeframeForMonthsView } from 'ee/roadmap/utils/roadmap_utils';

const mockTimeframeMonths = getTimeframeForMonthsView(mockTimeframeInitialDate);

describe('~/todos/app.vue', () => {
  let wrapper;

  const createWrapper = ({
    hasFiltersApplied = false,
    presetType = PRESET_TYPES.MONTHS,
    timeframeStart = mockTimeframeMonths[0],
    timeframeEnd = mockTimeframeMonths[mockTimeframeMonths.length - 1],
  }) => {
    wrapper = extendedWrapper(
      shallowMount(EpicsListEmpty, {
        propsData: {
          presetType,
          timeframeStart,
          timeframeEnd,
          emptyStateIllustrationPath: mockSvgPath,
          hasFiltersApplied,
        },
        provide: {
          newEpicPath: TEST_HOST,
          listEpicsPath: TEST_HOST,
        },
      }),
    );
  };

  beforeEach(() => {
    createWrapper({});
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findDefaultMessage = () => wrapper.findByTestId('default-message');

  it('renders default message', () => {
    expect(findDefaultMessage().text()).toBe(wrapper.vm.message);
  });
});
