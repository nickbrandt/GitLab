import Vuex from 'vuex';
import { shallowMount, mount, createLocalVue } from '@vue/test-utils';
import { GlLoadingIcon, GlNewDropdownItem } from '@gitlab/ui';
import durationChartStore from 'ee/analytics/cycle_analytics/store/modules/duration_chart';
import Scatterplot from 'ee/analytics/shared/components/scatterplot.vue';
import DurationChart from 'ee/analytics/cycle_analytics/components/duration_chart.vue';
import StageDropdownFilter from 'ee/analytics/cycle_analytics/components/stage_dropdown_filter.vue';
import {
  allowedStages as stages,
  durationChartPlottableData as durationData,
  durationChartPlottableMedianData as durationMedianData,
} from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

const actionSpies = {
  fetchDurationData: jest.fn(),
  updateSelectedDurationChartStages: jest.fn(),
};

const fakeStore = ({ initialGetters, initialState }) =>
  new Vuex.Store({
    modules: {
      durationChart: {
        ...durationChartStore,
        getters: {
          durationChartPlottableData: () => durationData,
          durationChartMedianData: () => durationMedianData,
          ...initialGetters,
        },
        state: {
          isLoading: false,
          ...initialState,
        },
      },
    },
  });

function createComponent({
  mountFn = shallowMount,
  stubs = {},
  initialState = {},
  initialGetters = {},
  props = {},
} = {}) {
  return mountFn(DurationChart, {
    localVue,
    store: fakeStore({ initialState, initialGetters }),
    propsData: {
      stages,
      ...props,
    },
    methods: actionSpies,
    stubs: {
      GlLoadingIcon: true,
      Scatterplot: true,
      StageDropdownFilter: true,
      ...stubs,
    },
  });
}

describe('DurationChart', () => {
  let wrapper;

  const findNoDataContainer = _wrapper => _wrapper.find({ ref: 'duration-chart-no-data' });
  const findScatterPlot = _wrapper => _wrapper.find(Scatterplot);
  const findStageDropdown = _wrapper => _wrapper.find(StageDropdownFilter);
  const findLoader = _wrapper => _wrapper.find(GlLoadingIcon);

  const selectStage = (_wrapper, index = 0) => {
    findStageDropdown(_wrapper)
      .findAll(GlNewDropdownItem)
      .at(index)
      .vm.$emit('click');
  };

  beforeEach(() => {
    wrapper = createComponent({});
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders the duration chart', () => {
    expect(wrapper.html()).toMatchSnapshot();
  });

  it('renders the scatter plot', () => {
    expect(findScatterPlot(wrapper).exists()).toBe(true);
  });

  it('renders the stage dropdown', () => {
    expect(findStageDropdown(wrapper).exists()).toBe(true);
  });

  describe('when a stage is selected', () => {
    const selectedIndex = 1;
    const selectedStages = stages.filter((_, index) => index !== selectedIndex);

    beforeEach(() => {
      wrapper = createComponent({ stubs: { StageDropdownFilter } });
      selectStage(wrapper, selectedIndex);
    });

    it('calls the `updateSelectedDurationChartStages` action', () => {
      expect(actionSpies.updateSelectedDurationChartStages).toHaveBeenCalledWith(selectedStages);
    });
  });

  describe('with no stages', () => {
    beforeEach(() => {
      wrapper = createComponent({
        mountFn: mount,
        props: { stages: [] },
        stubs: { StageDropdownFilter: false },
      });
    });

    it('does not render the stage dropdown', () => {
      expect(findStageDropdown(wrapper).exists()).toBe(false);
    });
  });

  describe('with no chart data', () => {
    beforeEach(() => {
      wrapper = createComponent({
        initialGetters: {
          durationChartPlottableData: () => [],
          durationChartMedianData: () => [],
        },
      });
    });

    it('renders the no data available message', () => {
      expect(findNoDataContainer(wrapper).text()).toEqual(
        'There is no data available. Please change your selection.',
      );
    });
  });

  describe('when isLoading=true', () => {
    beforeEach(() => {
      wrapper = createComponent({ initialState: { isLoading: true } });
    });

    it('renders a loader', () => {
      expect(findLoader(wrapper).exists()).toBe(true);
    });
  });
});
