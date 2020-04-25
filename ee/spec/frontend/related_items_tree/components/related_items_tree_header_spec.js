import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlDeprecatedButton, GlTooltip, GlIcon } from '@gitlab/ui';

import RelatedItemsTreeHeader from 'ee/related_items_tree/components/related_items_tree_header.vue';
import createDefaultStore from 'ee/related_items_tree/store';
import * as epicUtils from 'ee/related_items_tree/utils/epic_utils';
import { issuableTypesMap } from 'ee/related_issues/constants';
import EpicActionsSplitButton from 'ee/related_items_tree/components/epic_actions_split_button.vue';

import { mockInitialConfig, mockParentItem, mockQueryResponse } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

const createComponent = ({ slots } = {}) => {
  const store = createDefaultStore();
  const children = epicUtils.processQueryResponse(mockQueryResponse.data.group);

  store.dispatch('setInitialConfig', mockInitialConfig);
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
    localVue,
    store,
    slots,
  });
};

describe('RelatedItemsTree', () => {
  describe('RelatedItemsTreeHeader', () => {
    let wrapper;

    const findAddIssuesButton = () => wrapper.find(GlDeprecatedButton);
    const findEpicsSplitButton = () => wrapper.find(EpicActionsSplitButton);

    afterEach(() => {
      wrapper.destroy();
    });

    describe('badgeTooltip', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      it('returns string containing epic count based on available direct children within state', () => {
        expect(wrapper.find(GlTooltip).text()).toContain(`Epics •
        1 open, 1 closed`);
      });

      it('returns string containing issue count based on available direct children within state', () => {
        expect(wrapper.find(GlTooltip).text()).toContain(`Issues •
        1 open, 1 closed`);
      });
    });

    describe('epic actions split button', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      describe('showAddEpicForm event', () => {
        let toggleAddItemForm;

        beforeEach(() => {
          toggleAddItemForm = jest.fn();
          wrapper.vm.$store.hotUpdate({
            actions: {
              toggleAddItemForm,
            },
          });
        });

        it('dispatches toggleAddItemForm action', () => {
          findEpicsSplitButton().vm.$emit('showAddEpicForm');

          expect(toggleAddItemForm).toHaveBeenCalled();

          const payload = toggleAddItemForm.mock.calls[0][1];

          expect(payload).toEqual({
            issuableType: issuableTypesMap.EPIC,
            toggleState: true,
          });
        });
      });

      describe('showCreateEpicForm event', () => {
        let toggleCreateEpicForm;

        beforeEach(() => {
          toggleCreateEpicForm = jest.fn();
          wrapper.vm.$store.hotUpdate({
            actions: {
              toggleCreateEpicForm,
            },
          });
        });

        it('dispatches toggleCreateEpicForm action', () => {
          findEpicsSplitButton().vm.$emit('showCreateEpicForm');

          expect(toggleCreateEpicForm).toHaveBeenCalled();

          const payload =
            toggleCreateEpicForm.mock.calls[toggleCreateEpicForm.mock.calls.length - 1][1];

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
          setItemInputValue = jest.fn();
          toggleAddItemForm = jest.fn();
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

          expect(setItemInputValue.mock.calls[setItemInputValue.mock.calls.length - 1][1]).toBe('');

          expect(toggleAddItemForm).toHaveBeenCalled();

          const payload = toggleAddItemForm.mock.calls[setItemInputValue.mock.calls.length - 1][1];

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

      describe('when sub-epics feature is available', () => {
        it('renders epics count and gl-icon', () => {
          const epicsEl = wrapper.findAll('.issue-count-badge > span').at(0);
          const epicIcon = epicsEl.find(GlIcon);

          expect(epicsEl.text().trim()).toContain('2');
          expect(epicIcon.isVisible()).toBe(true);
          expect(epicIcon.props('name')).toBe('epic');
        });

        it('renders `Add an epic` dropdown button', () => {
          expect(findEpicsSplitButton().isVisible()).toBe(true);
        });
      });

      describe('when sub-epics feature is not available', () => {
        beforeEach(() => {
          wrapper.vm.$store.commit('SET_INITIAL_CONFIG', {
            ...mockInitialConfig,
            allowSubEpics: false,
          });

          return wrapper.vm.$nextTick();
        });

        it('does not render epics count and gl-icon', () => {
          const countBadgesEl = wrapper.findAll('.issue-count-badge > span');
          const badgeIcon = countBadgesEl.at(0).find(GlIcon);

          expect(countBadgesEl).toHaveLength(1);
          expect(badgeIcon.props('name')).toBe('issues');
        });

        it('does not render `Add an epic` dropdown button', () => {
          expect(findEpicsSplitButton().exists()).toBe(false);
        });
      });

      it('renders issues count and gl-icon', () => {
        const issuesEl = wrapper.findAll('.issue-count-badge > span').at(1);
        const issueIcon = issuesEl.find(GlIcon);

        expect(issuesEl.text().trim()).toContain('2');
        expect(issueIcon.isVisible()).toBe(true);
        expect(issueIcon.props('name')).toBe('issues');
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
