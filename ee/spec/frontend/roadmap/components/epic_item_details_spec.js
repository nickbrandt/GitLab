import { GlButton, GlIcon, GlTooltip } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import createStore from 'ee/roadmap/store';
import EpicItemDetails from 'ee/roadmap/components/epic_item_details.vue';
import eventHub from 'ee/roadmap/event_hub';
import {
  mockGroupId,
  mockFormattedEpic,
  mockFormattedChildEpic2,
  mockFormattedChildEpic1,
} from 'ee_jest/roadmap/mock_data';

let store;

const createComponent = ({
  epic = mockFormattedEpic,
  currentGroupId = mockGroupId,
  timeframeString = 'Jul 10, 2017 – Jun 2, 2018',
  childLevel = 0,
  childrenFlags = { '41': { itemExpanded: false } },
  hasFiltersApplied = false,
  isChildrenEmpty = false,
} = {}) => {
  return shallowMount(EpicItemDetails, {
    store,
    propsData: {
      epic,
      currentGroupId,
      timeframeString,
      childLevel,
      childrenFlags,
      hasFiltersApplied,
      isChildrenEmpty,
    },
  });
};

const getTitle = wrapper => wrapper.find('.epic-title');

const getGroupName = wrapper => wrapper.find('.epic-group');

const getExpandIconButton = wrapper => wrapper.find(GlButton);

const getChildEpicsCount = wrapper => wrapper.find({ ref: 'childEpicsCount' });

describe('EpicItemDetails', () => {
  let wrapper;

  beforeEach(() => {
    store = createStore();
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('epic title', () => {
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
          id: '41',
          mockFormattedEpic,
          groupId: 1,
          groupName: 'Bar',
          groupFullName: 'Foo / Bar',
          descendantCounts: {
            closedIssues: 3,
            openedIssues: 2,
          },
        };

        wrapper.setProps({ epic, currentGroupId: 2 });
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

        wrapper.setProps({ epic, currentGroupId: 1 });
      });

      it('is hidden', () => {
        expect(getGroupName(wrapper).exists()).toBe(false);
      });
    });
  });

  describe('timeframe', () => {
    it('is displayed', () => {
      const timeframe = wrapper.find('.epic-timeframe');

      expect(timeframe.text()).toBe('Jul 10, 2017 – Jun 2, 2018');
    });
  });

  describe('childMarginClassname', () => {
    it('childMarginClassname returns class for level 1 child is childLevel is 1', () => {
      wrapper.setProps({ childLevel: 1 });
      expect(wrapper.vm.childMarginClassname).toEqual('ml-4');
    });

    it('childMarginClassname returns class for level 2 child is childLevel is 2', () => {
      wrapper.setProps({ childLevel: 2 });
      expect(wrapper.vm.childMarginClassname).toEqual('ml-6');
    });
  });

  describe('epic', () => {
    beforeEach(() => {
      store.state.allowSubEpics = true;
    });

    describe('expand icon', () => {
      it('is hidden when epic has no child epics', () => {
        const epic = {
          ...mockFormattedEpic,
          hasChildren: false,
        };
        wrapper = createComponent({ epic });

        expect(getExpandIconButton(wrapper).classes()).toContain('invisible');
      });

      it('is shown when epic has child epics', () => {
        const epic = {
          ...mockFormattedEpic,
          hasChildren: true,
          children: {
            edges: [mockFormattedChildEpic1],
          },
        };
        wrapper = createComponent({ epic });

        expect(getExpandIconButton(wrapper).classes()).not.toContain('invisible');
      });

      it('shows "chevron-right" icon when child epics are not expanded', () => {
        wrapper = createComponent();

        expect(wrapper.find(GlIcon).attributes('name')).toBe('chevron-right');
      });

      it('shows "chevron-down" icon when child epics are expanded', () => {
        const epic = {
          ...mockFormattedEpic,
          hasChildren: true,
        };
        wrapper = createComponent({
          epic,
          childrenFlags: {
            '41': { itemExpanded: true },
          },
        });

        expect(wrapper.find(GlIcon).attributes('name')).toBe('chevron-down');
      });

      it('shows "information-o" icon when child epics are expanded but no children are returned due to applied filters', () => {
        const epic = {
          ...mockFormattedEpic,
          hasChildren: true,
        };
        wrapper = createComponent({
          epic,
          childrenFlags: {
            '41': { itemExpanded: true },
          },
          hasFiltersApplied: true,
          isChildrenEmpty: true,
        });

        expect(wrapper.find(GlIcon).attributes('name')).toBe('information-o');
      });

      it('has "Expand child epics" label when child epics are not expanded', () => {
        wrapper = createComponent();

        expect(getExpandIconButton(wrapper).attributes('aria-label')).toBe('Expand child epics');
      });

      it('has "Collapse child epics" label when child epics are expanded', () => {
        const epic = {
          ...mockFormattedEpic,
          hasChildren: true,
        };
        wrapper = createComponent({
          epic,
          childrenFlags: {
            '41': { itemExpanded: true },
          },
        });

        expect(getExpandIconButton(wrapper).attributes('aria-label')).toBe('Collapse child epics');
      });

      it('has "No child epics match applied filters" label when child epics are expanded', () => {
        const epic = {
          ...mockFormattedEpic,
          hasChildren: true,
        };
        wrapper = createComponent({
          epic,
          childrenFlags: {
            '41': { itemExpanded: true },
          },
          hasFiltersApplied: true,
          isChildrenEmpty: true,
        });

        expect(getExpandIconButton(wrapper).attributes('aria-label')).toBe(
          'No child epics match applied filters',
        );
      });

      it('emits toggleIsEpicExpanded event when clicked', () => {
        jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

        const id = 41;
        const epic = {
          ...mockFormattedEpic,
          id,
          children: {
            edges: [mockFormattedChildEpic1],
          },
        };
        wrapper = createComponent({ epic });

        getExpandIconButton(wrapper).vm.$emit('click');

        expect(eventHub.$emit).toHaveBeenCalledWith('toggleIsEpicExpanded', epic);
      });

      it('is hidden when it is child epic', () => {
        const epic = {
          ...mockFormattedEpic,
          isChildEpic: true,
        };
        wrapper = createComponent({ epic });

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
          descendantCounts: {
            openedEpics: 0,
            closedEpics: 2,
          },
        };
        wrapper = createComponent({ epic });

        expect(getChildEpicsCount(wrapper).text()).toBe('2');
      });

      it('shows the count as 0 when there are no child epics', () => {
        const epic = {
          ...mockFormattedEpic,
          descendantCounts: {
            openedEpics: 0,
            closedEpics: 0,
          },
        };
        wrapper = createComponent({ epic });

        expect(getChildEpicsCount(wrapper).text()).toBe('0');
      });

      it('has a tooltip with the count', () => {
        const epic = {
          ...mockFormattedEpic,
          children: {
            edges: [mockFormattedChildEpic1],
          },
          descendantCounts: {
            openedEpics: 0,
            closedEpics: 1,
          },
        };
        wrapper = createComponent({ epic });

        expect(wrapper.find(GlTooltip).text()).toBe('1 child epic');
      });

      it('has a tooltip with the count and explanation if search is being performed', () => {
        const epic = {
          ...mockFormattedEpic,
          children: {
            edges: [mockFormattedChildEpic1],
          },
          descendantCounts: {
            openedEpics: 0,
            closedEpics: 1,
          },
        };
        wrapper = createComponent({ epic, hasFiltersApplied: true });

        expect(wrapper.find(GlTooltip).text()).toBe(
          '1 child epic Some child epics may be hidden due to applied filters',
        );
      });

      it('does not render if the user license does not support child epics', () => {
        store.state.allowSubEpics = false;
        wrapper = createComponent();
        expect(getChildEpicsCount(wrapper).exists()).toBe(false);
      });
    });
  });
});
