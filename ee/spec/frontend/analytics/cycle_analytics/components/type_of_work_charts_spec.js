import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import TypeOfWorkCharts from 'ee/analytics/cycle_analytics/components/type_of_work_charts.vue';
import TasksByTypeChart from 'ee/analytics/cycle_analytics/components/tasks_by_type/tasks_by_type_chart.vue';
import TasksByTypeFilters from 'ee/analytics/cycle_analytics/components/tasks_by_type/tasks_by_type_filters.vue';
import { tasksByTypeData, taskByTypeFilters } from '../mock_data';
import {
  TASKS_BY_TYPE_SUBJECT_MERGE_REQUEST,
  TASKS_BY_TYPE_FILTERS,
} from 'ee/analytics/cycle_analytics/constants';

describe('TypeOfWorkCharts', () => {
  function createComponent({ props = {}, stubs = {} } = {}) {
    return shallowMount(TypeOfWorkCharts, {
      propsData: {
        isLoading: false,
        tasksByTypeChartData: tasksByTypeData,
        selectedTasksByTypeFilters: taskByTypeFilters,
        ...props,
      },
      stubs: {
        TasksByTypeChart: false,
        TasksByTypeFilters: false,
        ...stubs,
      },
    });
  }

  let wrapper = null;

  const findSubjectFilters = _wrapper => _wrapper.find(TasksByTypeFilters);
  const findTasksByTypeChart = _wrapper => _wrapper.find(TasksByTypeChart);
  const findLoader = _wrapper => _wrapper.find(GlLoadingIcon);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with data', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders the task by type chart', () => {
      expect(findTasksByTypeChart(wrapper).exists()).toBe(true);
    });

    it('does not render the loading icon', () => {
      expect(findLoader(wrapper).exists()).toBe(false);
    });
  });

  describe('when a filter is selected', () => {
    const payload = {
      filter: TASKS_BY_TYPE_FILTERS.SUBJECT,
      value: TASKS_BY_TYPE_SUBJECT_MERGE_REQUEST,
    };

    beforeEach(() => {
      wrapper = createComponent();
      findSubjectFilters(wrapper).vm.$emit('updateFilter', payload);
      return wrapper.vm.$nextTick();
    });

    it('emits the `updateFilter` event', () => {
      expect(wrapper.emitted('updateFilter')).toBeDefined();
      expect(wrapper.emitted('updateFilter')[0]).toEqual([payload]);
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
