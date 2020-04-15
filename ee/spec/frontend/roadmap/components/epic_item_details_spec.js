import { GlButton, GlIcon, GlTooltip } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EpicItemDetails from 'ee/roadmap/components/epic_item_details.vue';
import eventHub from 'ee/roadmap/event_hub';
import {
  mockGroupId,
  mockFormattedEpic,
  mockFormattedChildEpic2,
  mockFormattedChildEpic1,
} from 'ee_jest/roadmap/mock_data';

const createComponent = (
  epic = mockFormattedEpic,
  currentGroupId = mockGroupId,
  timeframeString = 'Jul 10, 2017 – Jun 2, 2018',
) => {
  return shallowMount(EpicItemDetails, {
    propsData: {
      epic,
      currentGroupId,
      timeframeString,
    },
  });
};

const getTitle = wrapper => wrapper.find('.epic-title');

const getGroupName = wrapper => wrapper.find('.epic-group');

const getExpandIconButton = wrapper => wrapper.find(GlButton);

const getChildEpicsCount = wrapper => wrapper.find({ ref: 'childEpicsCount' });

describe('EpicItemDetails', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('epic title', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('is displayed', () => {
      expect(getTitle(wrapper).text()).toBe(mockFormattedEpic.title);
    });

    it('contains a link to the epic', () => {
      expect(getTitle(wrapper).attributes('href')).toBe(mockFormattedEpic.webUrl);
    });
  });

  describe('epic group name', () => {
    describe('when the epic group ID is different from the current group ID', () => {
      let epic;

      beforeEach(() => {
        epic = {
          mockFormattedEpic,
          groupId: 1,
          groupName: 'Bar',
          groupFullName: 'Foo / Bar',
        };

        wrapper = createComponent(epic, 2);
      });

      it('is displayed', () => {
        expect(getGroupName(wrapper).text()).toContain(epic.groupName);
      });

      it('is set to the title attribute', () => {
        expect(getGroupName(wrapper).attributes('title')).toBe(epic.groupFullName);
      });
    });

    describe('when the epic group ID is the same as the current group ID', () => {
      let epic;

      beforeEach(() => {
        epic = {
          ...mockFormattedEpic,
          groupId: 1,
          groupName: 'Bar',
          groupFullName: 'Foo / Bar',
        };

        wrapper = createComponent(epic, 1);
      });

      it('is hidden', () => {
        expect(getGroupName(wrapper).exists()).toBe(false);
      });
    });
  });

  describe('timeframe', () => {
    it('is displayed', () => {
      wrapper = createComponent();
      const timeframe = wrapper.find('.epic-timeframe');

      expect(timeframe.text()).toBe('Jul 10, 2017 – Jun 2, 2018');
    });
  });

  describe('epic', () => {
    describe('expand icon', () => {
      it('is hidden when epic has no child epics', () => {
        wrapper = createComponent();

        expect(getExpandIconButton(wrapper).classes()).toContain('invisible');
      });

      it('is shown when epic has child epics', () => {
        const epic = {
          ...mockFormattedEpic,
          children: {
            edges: [mockFormattedChildEpic1],
          },
        };
        wrapper = createComponent(epic);

        expect(getExpandIconButton(wrapper).classes()).not.toContain('invisible');
      });

      it('shows "chevron-right" icon when child epics are not expanded', () => {
        wrapper = createComponent();

        expect(wrapper.find(GlIcon).attributes('name')).toBe('chevron-right');
      });

      it('shows "chevron-down" icon when child epics are expanded', () => {
        const epic = {
          ...mockFormattedEpic,
          isChildEpicShowing: true,
        };
        wrapper = createComponent(epic);

        expect(wrapper.find(GlIcon).attributes('name')).toBe('chevron-down');
      });

      it('has "Expand child epics" label when child epics are not expanded', () => {
        wrapper = createComponent();

        expect(getExpandIconButton(wrapper).attributes('aria-label')).toBe('Expand child epics');
      });

      it('has "Collapse child epics" label when child epics are expanded', () => {
        const epic = {
          ...mockFormattedEpic,
          isChildEpicShowing: true,
        };
        wrapper = createComponent(epic);

        expect(getExpandIconButton(wrapper).attributes('aria-label')).toBe('Collapse child epics');
      });

      it('emits toggleIsEpicExpanded event when clicked', () => {
        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

        const id = 42;
        const epic = {
          ...mockFormattedEpic,
          id,
          children: {
            edges: [mockFormattedChildEpic1],
          },
        };
        wrapper = createComponent(epic);

        getExpandIconButton(wrapper).vm.$emit('click');

        expect(eventHub.$emit).toHaveBeenCalledWith('toggleIsEpicExpanded', id);
      });

      it('is hidden when it is child epic', () => {
        const epic = {
          ...mockFormattedEpic,
          isChildEpic: true,
        };
        wrapper = createComponent(epic);

        expect(getExpandIconButton(wrapper).classes()).toContain('invisible');
      });
    });

    describe('child epics count', () => {
      it('shows the correct count of child epics', () => {
        const epic = {
          ...mockFormattedEpic,
          children: {
            edges: [mockFormattedChildEpic1, mockFormattedChildEpic2],
          },
        };
        wrapper = createComponent(epic);

        expect(getChildEpicsCount(wrapper).text()).toBe('2');
      });

      it('shows the count as 0 when there are no child epics', () => {
        wrapper = createComponent();

        expect(getChildEpicsCount(wrapper).text()).toBe('0');
      });

      it('has a tooltip with the count', () => {
        const epic = {
          ...mockFormattedEpic,
          children: {
            edges: [mockFormattedChildEpic1],
          },
        };
        wrapper = createComponent(epic);

        expect(wrapper.find(GlTooltip).text()).toBe('1 child epic');
      });

      it('is hidden when it is a child epic', () => {
        const epic = {
          ...mockFormattedEpic,
          isChildEpic: true,
        };
        wrapper = createComponent(epic);

        expect(getChildEpicsCount(wrapper).classes()).toContain('invisible');
      });
    });
  });
});
