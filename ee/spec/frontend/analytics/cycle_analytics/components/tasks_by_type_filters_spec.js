import { shallowMount, mount } from '@vue/test-utils';
import { GlDropdownItem, GlSegmentedControl } from '@gitlab/ui';
import TasksByTypeFilters from 'ee/analytics/cycle_analytics/components/tasks_by_type_filters.vue';
import {
  TASKS_BY_TYPE_SUBJECT_ISSUE,
  TASKS_BY_TYPE_SUBJECT_MERGE_REQUEST,
  TASKS_BY_TYPE_FILTERS,
} from 'ee/analytics/cycle_analytics/constants';
import { shouldFlashAMessage } from '../helpers';
import { groupLabels } from '../mock_data';

const selectedLabelIds = [groupLabels[0].id];

const findSubjectFilters = ctx => ctx.find(GlSegmentedControl);
const findSelectedSubjectFilters = ctx => findSubjectFilters(ctx).attributes('checked');
const findDropdownLabels = ctx => ctx.findAll(GlDropdownItem);

const selectLabelAtIndex = (ctx, index) => {
  findDropdownLabels(ctx)
    .at(index)
    .vm.$emit('click');
  return ctx.vm.$nextTick();
};

function createComponent({ props = {}, mountFn = shallowMount }) {
  return mountFn(TasksByTypeFilters, {
    propsData: {
      selectedLabelIds,
      labels: groupLabels,
      subjectFilter: TASKS_BY_TYPE_SUBJECT_ISSUE,
      ...props,
    },
    stubs: {
      GlNewDropdown: true,
      GlDropdownItem: true,
    },
  });
}

describe('TasksByTypeFilters', () => {
  let wrapper = null;

  beforeEach(() => {
    wrapper = createComponent({});
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('labels', () => {
    beforeEach(() => {
      wrapper = createComponent({});
    });

    it('emits the `updateFilter` event when a subject label is clicked', () => {
      expect(wrapper.emitted('updateFilter')).toBeUndefined();
      return selectLabelAtIndex(wrapper, 0).then(() => {
        expect(wrapper.emitted('updateFilter')).toBeDefined();

        expect(wrapper.emitted('updateFilter')[0]).toEqual([
          { filter: TASKS_BY_TYPE_FILTERS.LABEL, value: groupLabels[0].id },
        ]);
      });
    });

    describe('with the warningMessageThreshold label threshold reached', () => {
      beforeEach(() => {
        setFixtures('<div class="flash-container"></div>');
        wrapper = createComponent({
          props: {
            maxLabels: 5,
            selectedLabelIds: [groupLabels[0].id, groupLabels[1].id],
            warningMessageThreshold: 2,
          },
        });

        return selectLabelAtIndex(wrapper, 2);
      });

      it('should indicate how many labels are selected', () => {
        expect(wrapper.text()).toContain('2 selected (5 max)');
      });
    });

    describe('with maximum labels selected', () => {
      beforeEach(() => {
        setFixtures('<div class="flash-container"></div>');
        wrapper = createComponent({
          props: {
            maxLabels: 2,
            selectedLabelIds: [groupLabels[0].id, groupLabels[1].id],
            warningMessageThreshold: 1,
          },
        });

        return selectLabelAtIndex(wrapper, 2);
      });

      it('should indicate how many labels are selected', () => {
        expect(wrapper.text()).toContain('2 selected (2 max)');
      });

      it('should not allow selecting another label', () => {
        expect(wrapper.emitted('updateFilter')).toBeUndefined();
      });

      it('should display a message', () => {
        shouldFlashAMessage('Only 2 labels can be selected at this time');
      });
    });
  });

  describe('subject', () => {
    it('has the issue subject set by default', () => {
      expect(findSelectedSubjectFilters(wrapper)).toBe(TASKS_BY_TYPE_SUBJECT_ISSUE);
    });

    it('emits the `updateFilter` event when a subject filter is clicked', () => {
      wrapper = createComponent({ mountFn: mount });
      expect(wrapper.emitted('updateFilter')).toBeUndefined();

      findSubjectFilters(wrapper)
        .findAll('label:not(.active)')
        .at(0)
        .trigger('click');

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.emitted('updateFilter')).toBeDefined();
        expect(wrapper.emitted('updateFilter')[0]).toEqual([
          {
            filter: TASKS_BY_TYPE_FILTERS.SUBJECT,
            value: TASKS_BY_TYPE_SUBJECT_MERGE_REQUEST,
          },
        ]);
      });
    });
  });
});
