import { shallowMount, mount } from '@vue/test-utils';
import { GlNewDropdown, GlNewDropdownItem, GlSegmentedControl } from '@gitlab/ui';
import TasksByTypeFilters from 'ee/analytics/cycle_analytics/components/tasks_by_type_filters.vue';
import {
  TASKS_BY_TYPE_SUBJECT_ISSUE,
  TASKS_BY_TYPE_SUBJECT_MERGE_REQUEST,
  TASKS_BY_TYPE_FILTERS,
} from 'ee/analytics/cycle_analytics/constants';
import { groupLabels } from '../mock_data';

const selectedLabelIds = [groupLabels[0].id];

const findSubjectFilters = ctx =>
  ctx.find('.js-tasks-by-type-chart-filters-subject').find(GlSegmentedControl);
const findSelectedSubjectFilters = ctx => findSubjectFilters(ctx).attributes('checked');
const findDropdown = ctx => ctx.find(GlNewDropdown);
const findDropdownLabels = ctx =>
  ctx.find('.js-tasks-by-type-chart-filters-labels').findAll(GlNewDropdownItem);

const selectLabelAtIndex = (ctx, index) => {
  findDropdownLabels(ctx)
    .at(index)
    .vm.$emit('click');
  return ctx.vm.$nextTick();
};

function createComponent({ props = {}, shallow = true }) {
  const fn = shallow ? shallowMount : mount;
  return fn(TasksByTypeFilters, {
    propsData: {
      selectedLabelIds,
      labels: groupLabels,
      subjectFilter: TASKS_BY_TYPE_SUBJECT_ISSUE,
      ...props,
    },
    stubs: {
      GlNewDropdown: true,
      GlNewDropdownItem: true,
    },
  });
}

describe('TasksByTypeFilters', () => {
  let wrapper = null;

  describe('with data available', () => {
    beforeEach(() => {
      wrapper = createComponent({});
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('should render the filters', () => {
      expect(wrapper.html()).toMatchSnapshot();
    });

    describe('labels', () => {
      it(`should have ${selectedLabelIds.length} selected`, () => {
        expect(wrapper.text()).toContain('1 selected (15 max)');
      });

      describe('with label dropdown open', () => {
        beforeEach(() => {
          wrapper = createComponent({});
        });

        it('renders the group labels as dropdown items', () => {
          expect(findDropdown(wrapper).html()).toMatchSnapshot();
        });

        it('emits the `updateFilter` event when a subject label is clicked', () => {
          expect(wrapper.emitted().updateFilter).toBeUndefined();
          return selectLabelAtIndex(wrapper, 0).then(() => {
            expect(wrapper.emitted().updateFilter).toBeDefined();

            expect(wrapper.emitted().updateFilter[0]).toEqual([
              { filter: TASKS_BY_TYPE_FILTERS.LABEL, value: groupLabels[0].id },
            ]);
          });
        });

        describe('with maximum labels selected', () => {
          beforeEach(() => {
            wrapper = createComponent({
              props: {
                maxLabels: 2,
                selectedLabelIds: [groupLabels[0].id, groupLabels[1].id],
              },
            });
          });

          it('should not allow selecting another label', () => {
            expect(wrapper.emitted().updateFilter).toBeUndefined();

            return selectLabelAtIndex(wrapper, 2).then(() => {
              expect(wrapper.emitted().updateFilter).toBeUndefined();
            });
          });
        });
      });
    });

    describe('subject', () => {
      it('has subject filters', () => {
        expect(findSubjectFilters(wrapper).html()).toMatchSnapshot();
      });

      it('has the issue subject set by default', () => {
        expect(findSelectedSubjectFilters(wrapper)).toBe(TASKS_BY_TYPE_SUBJECT_ISSUE);
      });

      it('emits the `updateFilter` event when a subject filter is clicked', () => {
        wrapper = createComponent({ shallow: false });
        expect(wrapper.emitted().updateFilter).toBeUndefined();

        findSubjectFilters(wrapper)
          .findAll('label:not(.active)')
          .at(0)
          .trigger('click');

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.emitted().updateFilter).toBeDefined();
          expect(wrapper.emitted().updateFilter[0]).toEqual([
            { filter: TASKS_BY_TYPE_FILTERS.SUBJECT, value: TASKS_BY_TYPE_SUBJECT_MERGE_REQUEST },
          ]);
        });
      });
    });
  });

  describe('no data available', () => {
    beforeEach(() => {
      wrapper = createComponent({});
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('should render the no data available message', () => {
      expect(wrapper.html()).toMatchSnapshot();
    });
  });
});
