import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';

import RelatedItemsTreeHeader from 'ee/related_items_tree/components/related_items_tree_header.vue';
import createDefaultStore from 'ee/related_items_tree/store';
import * as epicUtils from 'ee/related_items_tree/utils/epic_utils';
import { issuableTypesMap } from 'ee/related_issues/constants';
import EpicActionsSplitButton from 'ee/related_items_tree/components/epic_actions_split_button.vue';
import Icon from '~/vue_shared/components/icon.vue';

import {
  mockParentItem,
  mockQueryResponse,
} from '../../../javascripts/related_items_tree/mock_data';

const createComponent = ({ slots } = {}) => {
  const store = createDefaultStore();
  const children = epicUtils.processQueryResponse(mockQueryResponse.data.group);

  store.dispatch('setInitialParentItem', mockParentItem);
  store.dispatch('setItemChildren', {
    parentItem: mockParentItem,
    isSubItem: false,
    children,
  });
  store.dispatch('setItemChildrenFlags', {
    isSubItem: false,
    children,
  });
  store.dispatch('setChildrenCount', mockParentItem.descendantCounts);

  return shallowMount(RelatedItemsTreeHeader, {
    attachToDocument: true,
    sync: false,
    store,
    slots,
  });
};

describe('RelatedItemsTree', () => {
  describe('RelatedItemsTreeHeader', () => {
    let wrapper;

    const findAddIssuesButton = () => wrapper.find(GlButton);
    const findEpicsSplitButton = () => wrapper.find(EpicActionsSplitButton);

    afterEach(() => {
      wrapper.destroy();
    });

    describe('computed', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      describe('badgeTooltip', () => {
        it('returns string containing epic count and issues count based on available direct children within state', () => {
          expect(wrapper.vm.badgeTooltip).toBe('2 epics and 2 issues');
        });
      });
    });

    describe('epic actions split button', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      describe('showAddEpicForm event', () => {
        let toggleAddItemForm;

        beforeEach(() => {
          toggleAddItemForm = jasmine.createSpy();
          wrapper.vm.$store.hotUpdate({
            actions: {
              toggleAddItemForm,
            },
          });
        });

        it('dispatches toggleAddItemForm action', () => {
          findEpicsSplitButton().vm.$emit('showAddEpicForm');

          expect(toggleAddItemForm).toHaveBeenCalled();

          const payload = toggleAddItemForm.calls.mostRecent().args[1];

          expect(payload).toEqual({
            issuableType: issuableTypesMap.EPIC,
            toggleState: true,
          });
        });
      });

      describe('showCreateEpicForm event', () => {
        let toggleCreateEpicForm;

        beforeEach(() => {
          toggleCreateEpicForm = jasmine.createSpy();
          wrapper.vm.$store.hotUpdate({
            actions: {
              toggleCreateEpicForm,
            },
          });
        });

        it('dispatches toggleCreateEpicForm action', () => {
          findEpicsSplitButton().vm.$emit('showCreateEpicForm');

          expect(toggleCreateEpicForm).toHaveBeenCalled();

          const payload = toggleCreateEpicForm.calls.mostRecent().args[1];

          expect(payload).toEqual({ toggleState: true });
        });
      });
    });

    describe('add issues button', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      describe('click event', () => {
        let toggleAddItemForm;
        let setItemInputValue;

        beforeEach(() => {
          setItemInputValue = jasmine.createSpy();
          toggleAddItemForm = jasmine.createSpy();
          wrapper.vm.$store.hotUpdate({
            actions: {
              setItemInputValue,
              toggleAddItemForm,
            },
          });
        });

        it('dispatches setItemInputValue and toggleAddItemForm action', () => {
          findAddIssuesButton().vm.$emit('click');

          expect(setItemInputValue).toHaveBeenCalled();

          expect(setItemInputValue.calls.mostRecent().args[1]).toEqual('');

          expect(toggleAddItemForm).toHaveBeenCalled();

          const payload = toggleAddItemForm.calls.mostRecent().args[1];

          expect(payload).toEqual({
            issuableType: issuableTypesMap.ISSUE,
            toggleState: true,
          });
        });
      });
    });

    describe('template', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      it('renders item badges container', () => {
        const badgesContainerEl = wrapper.find('.issue-count-badge');

        expect(badgesContainerEl.isVisible()).toBe(true);
      });

      it('renders epics count and icon', () => {
        const epicsEl = wrapper.findAll('.issue-count-badge > span').at(0);
        const epicIcon = epicsEl.find(Icon);

        expect(epicsEl.text().trim()).toBe('2');
        expect(epicIcon.isVisible()).toBe(true);
        expect(epicIcon.props('name')).toBe('epic');
      });

      it('renders issues count and icon', () => {
        const issuesEl = wrapper.findAll('.issue-count-badge > span').at(1);
        const issueIcon = issuesEl.find(Icon);

        expect(issuesEl.text().trim()).toBe('2');
        expect(issueIcon.isVisible()).toBe(true);
        expect(issueIcon.props('name')).toBe('issues');
      });

      it('renders `Add an epic` dropdown button', () => {
        expect(findEpicsSplitButton().isVisible()).toBe(true);
      });

      it('renders `Add an issue` dropdown button', () => {
        const addIssueBtn = findAddIssuesButton();

        expect(addIssueBtn.isVisible()).toBe(true);
        expect(addIssueBtn.text()).toBe('Add an issue');
      });
    });

    describe('slots', () => {
      describe('issueActions', () => {
        it('defaults to button', () => {
          wrapper = createComponent();

          expect(findAddIssuesButton().exists()).toBe(true);
        });

        it('uses provided slot content', () => {
          const issueActions = {
            template: '<p>custom content</p>',
          };

          wrapper = createComponent({
            slots: {
              issueActions,
            },
          });

          expect(findAddIssuesButton().exists()).toBe(false);
          expect(wrapper.find(issueActions).exists()).toBe(true);
        });
      });
    });
  });
});
