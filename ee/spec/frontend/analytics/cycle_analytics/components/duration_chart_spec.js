import { shallowMount, mount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import $ from 'jquery';
import 'bootstrap';
import '~/gl_dropdown';
import Scatterplot from 'ee/analytics/shared/components/scatterplot.vue';
import DurationChart from 'ee/analytics/cycle_analytics/components/duration_chart.vue';
import StageDropdownFilter from 'ee/analytics/cycle_analytics/components/stage_dropdown_filter.vue';
import {
  allowedStages as stages,
  durationChartPlottableData as scatterData,
  durationChartPlottableMedianData as medianLineData,
} from '../mock_data';

function createComponent({ mountFn = shallowMount, props = {}, stubs = {} } = {}) {
  return mountFn(DurationChart, {
    propsData: {
      isLoading: false,
      stages,
      scatterData,
      medianLineData,
      ...props,
    },

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

  const openStageDropdown = _wrapper => {
    $(findStageDropdown(_wrapper).element).trigger('shown.bs.dropdown');
    return _wrapper.vm.$nextTick();
  };

  const selectStage = (_wrapper, index = 0) => {
    findStageDropdown(_wrapper)
      .findAll('a')
      .at(index)
      .trigger('click');
    return _wrapper.vm.$nextTick();
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
      wrapper = createComponent({ mountFn: mount, stubs: { StageDropdownFilter: false } });
      return openStageDropdown(wrapper).then(() => selectStage(wrapper, selectedIndex));
    });

    it('emits the stageSelected event', () => {
      expect(wrapper.emitted().stageSelected).toBeTruthy();
    });

    it('toggles the selected stage', () => {
      expect(wrapper.emitted('stageSelected')[0]).toEqual([selectedStages]);

      return selectStage(wrapper, selectedIndex).then(() => {
        const [updatedStages] = wrapper.emitted('stageSelected')[1];
        stages.forEach(stage => {
          expect(updatedStages).toContain(stage);
        });
      });
    });
  });

  describe('with no chart data', () => {
    beforeEach(() => {
      wrapper = createComponent({ props: { scatterData: [], medianLineData: [] } });
    });

    it('renders the no data available message', () => {
      expect(findNoDataContainer(wrapper).text()).toEqual(
        'There is no data available. Please change your selection.',
      );
    });
  });

  describe('while loading', () => {
    beforeEach(() => {
      wrapper = createComponent({ props: { isLoading: true } });
    });
    it('renders loading icon', () => {
      expect(findLoader(wrapper).exists()).toBe(true);
    });
  });
});
