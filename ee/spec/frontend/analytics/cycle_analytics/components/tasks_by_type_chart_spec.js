import { mount, shallowMount } from '@vue/test-utils';
import $ from 'jquery';
import 'bootstrap';
import '~/gl_dropdown';
import TasksByTypeChart from 'ee/analytics/cycle_analytics/components/tasks_by_type_chart.vue';
import {
  TASKS_BY_TYPE_SUBJECT_ISSUE,
  TASKS_BY_TYPE_SUBJECT_MERGE_REQUEST,
  TASKS_BY_TYPE_FILTERS,
} from 'ee/analytics/cycle_analytics/constants';
import { groupLabels } from '../mock_data';

const seriesNames = ['Cool label', 'Normal label'];
const data = [[0, 1, 2], [5, 2, 3], [2, 4, 1]];
const groupBy = ['Group 1', 'Group 2', 'Group 3'];
const filters = {
  selectedGroup: {
    id: 22,
    name: 'Gitlab Org',
    fullName: 'Gitlab Org',
    fullPath: 'gitlab-org',
  },
  selectedProjectIds: [],
  startDate: new Date('2019-12-11'),
  endDate: new Date('2020-01-10'),
  subject: TASKS_BY_TYPE_SUBJECT_ISSUE,
  selectedLabelIds: [1, 2, 3],
};

function createComponent({ props = {}, shallow = true, stubs = {} }) {
  const fn = shallow ? shallowMount : mount;
  return fn(TasksByTypeChart, {
    propsData: {
      filters,
      chartData: {
        groupBy,
        data,
        seriesNames,
      },
      labels: groupLabels,
      ...props,
    },
    stubs: {
      'gl-stacked-column-chart': true,
      'tasks-by-type-filters': true,
      ...stubs,
    },
  });
}

describe('TasksByTypeChart', () => {
  let wrapper = null;

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with data available', () => {
    beforeEach(() => {
      wrapper = createComponent({});
    });

    it('should render the loading chart', () => {
      expect(wrapper.html()).toMatchSnapshot();
    });

    describe('filters', () => {
      const findSubjectFilters = ctx => ctx.find('.js-tasks-by-type-chart-filters-subject');
      const findSelectedSubjectFilters = ctx =>
        ctx.find('.js-tasks-by-type-chart-filters-subject .active');
      const findLabelFilters = ctx => ctx.find('.js-tasks-by-type-chart-filters-labels');

      const findDropdown = ctx => ctx.find('.dropdown');
      const findDropdownContent = ctx => ctx.find('.dropdown-content');
      const openDropdown = ctx => {
        $(findDropdown(ctx).element)
          .parent()
          .trigger('shown.bs.dropdown');
      };

      beforeEach(() => {
        wrapper = createComponent({
          shallow: false,
          stubs: {
            'tasks-by-type-filters': false,
          },
        });
      });

      describe('labels', () => {
        it('has label filters', () => {
          expect(findLabelFilters(wrapper).html()).toMatchSnapshot();
        });

        describe('with label dropdown open', () => {
          beforeEach(() => {
            openDropdown(wrapper);
            return wrapper.vm.$nextTick();
          });

          it('renders the group labels as dropdown items', () => {
            expect(findDropdownContent(wrapper).html()).toMatchSnapshot();
          });

          it('emits the `updateFilter` event when a subject label is clicked', done => {
            expect(wrapper.emitted().updateFilter).toBeUndefined();

            findLabelFilters(wrapper)
              .findAll('.dropdown-menu-link')
              .at(0)
              .trigger('click');

            wrapper.vm.$nextTick(() => {
              expect(wrapper.emitted().updateFilter).toBeDefined();
              expect(wrapper.emitted().updateFilter[0]).toEqual([
                { filter: TASKS_BY_TYPE_FILTERS.LABEL, value: groupLabels[0].id },
              ]);
              done();
            });
          });
        });
      });

      describe('subject', () => {
        it('has subject filters', () => {
          expect(findSubjectFilters(wrapper).html()).toMatchSnapshot();
        });

        it('has the issue subject set by default', () => {
          expect(findSelectedSubjectFilters(wrapper).text()).toBe('Issues');
        });

        it('emits the `updateFilter` event when a subject filter is clicked', done => {
          expect(wrapper.emitted().updateFilter).toBeUndefined();

          findSubjectFilters(wrapper)
            .findAll('label:not(.active)')
            .at(0)
            .trigger('click');

          wrapper.vm.$nextTick(() => {
            expect(wrapper.emitted().updateFilter).toBeDefined();
            expect(wrapper.emitted().updateFilter[0]).toEqual([
              { filter: TASKS_BY_TYPE_FILTERS.SUBJECT, value: TASKS_BY_TYPE_SUBJECT_MERGE_REQUEST },
            ]);
            done();
          });
        });
      });
    });
  });

  describe('no data available', () => {
    beforeEach(() => {
      wrapper = createComponent({
        props: {
          chartData: {
            groupBy: [],
            data: [],
            seriesNames: [],
          },
        },
      });
    });

    it('should render the no data available message', () => {
      expect(wrapper.html()).toMatchSnapshot();
    });
  });
});
