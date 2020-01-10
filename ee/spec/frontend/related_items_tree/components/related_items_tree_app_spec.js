import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';

import RelatedItemsTreeApp from 'ee/related_items_tree/components/related_items_tree_app.vue';
import RelatedItemsTreeHeader from 'ee/related_items_tree/components/related_items_tree_header.vue';
import createDefaultStore from 'ee/related_items_tree/store';
import { issuableTypesMap } from 'ee/related_issues/constants';
import AddItemForm from 'ee/related_issues/components/add_issuable_form.vue';
import CreateIssueForm from 'ee/related_items_tree/components/create_issue_form.vue';
import IssueActionsSplitButton from 'ee/related_items_tree/components/issue_actions_split_button.vue';
import { TEST_HOST } from 'spec/test_constants';
import AxiosMockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { getJSONFixture } from 'helpers/fixtures';

// https://gitlab.com/gitlab-org/gitlab/issues/118456
import {
  mockInitialConfig,
  mockParentItem,
} from '../../../javascripts/related_items_tree/mock_data';

const mockProjects = getJSONFixture('static/projects.json');

const createComponent = () => {
  const store = createDefaultStore();

  store.dispatch('setInitialConfig', mockInitialConfig);
  store.dispatch('setInitialParentItem', mockParentItem);

  return shallowMount(RelatedItemsTreeApp, {
    store,
  });
};

describe('RelatedItemsTreeApp', () => {
  let axiosMock;
  let wrapper;

  const findAddItemForm = () => wrapper.find(AddItemForm);
  const findCreateIssueForm = () => wrapper.find(CreateIssueForm);
  const findIssueActionsSplitButton = () => wrapper.find(IssueActionsSplitButton);
  const showCreateIssueForm = () => {
    findIssueActionsSplitButton().vm.$emit('showCreateIssueForm');
    return axios.waitFor(mockInitialConfig.projectsEndpoint).then(() => wrapper.vm.$nextTick());
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    axiosMock.onGet(mockInitialConfig.projectsEndpoint).replyOnce(200, mockProjects);
  });

  afterEach(() => {
    wrapper.destroy();
    axiosMock.restore();
  });

  describe('methods', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    describe('getRawRefs', () => {
      it('returns array of references from provided string with spaces', () => {
        const value = '&1 &2 &3';
        const references = wrapper.vm.getRawRefs(value);

        expect(references.length).toBe(3);
        expect(references.join(' ')).toBe(value);
      });
    });

    describe('handlePendingItemRemove', () => {
      it('calls `removePendingReference` action with provided `index` param', () => {
        jest.spyOn(wrapper.vm, 'removePendingReference').mockImplementation();

        wrapper.vm.handlePendingItemRemove(0);

        expect(wrapper.vm.removePendingReference).toHaveBeenCalledWith(0);
      });
    });

    describe('handleAddItemFormInput', () => {
      const untouchedRawReferences = ['&1'];
      const touchedReference = '&2';

      it('calls `addPendingReferences` action with provided `untouchedRawReferences` param', () => {
        jest.spyOn(wrapper.vm, 'addPendingReferences').mockImplementation();

        wrapper.vm.handleAddItemFormInput({ untouchedRawReferences, touchedReference });

        expect(wrapper.vm.addPendingReferences).toHaveBeenCalledWith(untouchedRawReferences);
      });

      it('calls `setItemInputValue` action with provided `touchedReference` param', () => {
        jest.spyOn(wrapper.vm, 'setItemInputValue').mockImplementation();

        wrapper.vm.handleAddItemFormInput({ untouchedRawReferences, touchedReference });

        expect(wrapper.vm.setItemInputValue).toHaveBeenCalledWith(touchedReference);
      });
    });

    describe('handleAddItemFormBlur', () => {
      const newValue = '&1 &2';

      it('calls `addPendingReferences` action with provided `newValue` param', () => {
        jest.spyOn(wrapper.vm, 'addPendingReferences').mockImplementation();

        wrapper.vm.handleAddItemFormBlur(newValue);

        expect(wrapper.vm.addPendingReferences).toHaveBeenCalledWith(newValue.split(/\s+/));
      });

      it('calls `setItemInputValue` action with empty string', () => {
        jest.spyOn(wrapper.vm, 'setItemInputValue').mockImplementation();

        wrapper.vm.handleAddItemFormBlur(newValue);

        expect(wrapper.vm.setItemInputValue).toHaveBeenCalledWith('');
      });
    });

    describe('handleAddItemFormSubmit', () => {
      it('calls `addItem` action when `pendingReferences` prop in state is not empty', () => {
        const newValue = '&1 &2';
        jest.spyOn(wrapper.vm, 'addItem').mockImplementation();

        wrapper.vm.handleAddItemFormSubmit(newValue);

        expect(wrapper.vm.addItem).toHaveBeenCalled();
      });
    });

    describe('handleCreateEpicFormSubmit', () => {
      it('calls `createItem` action with `itemTitle` param', () => {
        const newValue = 'foo';
        jest.spyOn(wrapper.vm, 'createItem').mockImplementation();

        wrapper.vm.handleCreateEpicFormSubmit(newValue);

        expect(wrapper.vm.createItem).toHaveBeenCalledWith({
          itemTitle: newValue,
        });
      });
    });

    describe('handleAddItemFormCancel', () => {
      it('calls `toggleAddItemForm` actions with params `toggleState` as `false`', () => {
        jest.spyOn(wrapper.vm, 'toggleAddItemForm').mockImplementation();

        wrapper.vm.handleAddItemFormCancel();

        expect(wrapper.vm.toggleAddItemForm).toHaveBeenCalledWith({ toggleState: false });
      });

      it('calls `setPendingReferences` action with empty array', () => {
        jest.spyOn(wrapper.vm, 'setPendingReferences').mockImplementation();

        wrapper.vm.handleAddItemFormCancel();

        expect(wrapper.vm.setPendingReferences).toHaveBeenCalledWith([]);
      });

      it('calls `setItemInputValue` action with empty string', () => {
        jest.spyOn(wrapper.vm, 'setItemInputValue').mockImplementation();

        wrapper.vm.handleAddItemFormCancel();

        expect(wrapper.vm.setItemInputValue).toHaveBeenCalledWith('');
      });
    });

    describe('handleCreateEpicFormCancel', () => {
      it('calls `toggleCreateEpicForm` actions with params `toggleState`', () => {
        jest.spyOn(wrapper.vm, 'toggleCreateEpicForm').mockImplementation();

        wrapper.vm.handleCreateEpicFormCancel();

        expect(wrapper.vm.toggleCreateEpicForm).toHaveBeenCalledWith({ toggleState: false });
      });

      it('calls `setItemInputValue` action with empty string', () => {
        jest.spyOn(wrapper.vm, 'setItemInputValue').mockImplementation();

        wrapper.vm.handleCreateEpicFormCancel();

        expect(wrapper.vm.setItemInputValue).toHaveBeenCalledWith('');
      });
    });
  });

  describe('template', () => {
    beforeEach(() => {
      wrapper = createComponent();
      wrapper.vm.$store.dispatch('receiveItemsSuccess', {
        parentItem: mockParentItem,
        children: [],
        isSubItem: false,
      });
    });

    it('renders loading icon when `state.itemsFetchInProgress` prop is true', () => {
      wrapper.vm.$store.dispatch('requestItems', {
        parentItem: mockParentItem,
        isSubItem: false,
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find(GlLoadingIcon).isVisible()).toBe(true);
      });
    });

    it('renders tree container element when `state.itemsFetchInProgress` prop is false', () =>
      wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find('.related-items-tree').isVisible()).toBe(true);
      }));

    it('renders tree container element with `disabled-content` class when `state.itemsFetchInProgress` prop is false and `state.itemAddInProgress` or `state.itemCreateInProgress` is true', () => {
      wrapper.vm.$store.dispatch('requestAddItem');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find('.related-items-tree.disabled-content').isVisible()).toBe(true);
      });
    });

    it('renders tree header component', () =>
      wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find(RelatedItemsTreeHeader).isVisible()).toBe(true);
      }));

    it('renders item add/create form container element', () => {
      wrapper.vm.$store.dispatch('toggleAddItemForm', {
        toggleState: true,
        issuableType: issuableTypesMap.Epic,
      });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find('.add-item-form-container').isVisible()).toBe(true);
      });
    });

    it('does not render issue actions split button', () => {
      expect(findIssueActionsSplitButton().exists()).toBe(false);
    });

    it('does not render create issue form', () => {
      expect(findCreateIssueForm().exists()).toBe(false);
    });
  });

  describe('with epicNewIssue feature flag enabled', () => {
    beforeEach(() => {
      window.gon.features = { epicNewIssue: true };
      wrapper = createComponent();
      wrapper.vm.$store.state.itemsFetchInProgress = false;
      return wrapper.vm.$nextTick();
    });

    afterEach(() => {
      window.gon.features = {};
    });

    it('renders issue actions split button', () => {
      expect(findIssueActionsSplitButton().exists()).toBe(true);
    });

    describe('after split button emitted showAddIssueForm event', () => {
      it('shows add item form', () => {
        expect(findAddItemForm().exists()).toBe(false);

        findIssueActionsSplitButton().vm.$emit('showAddIssueForm');

        return wrapper.vm.$nextTick().then(() => {
          expect(findAddItemForm().exists()).toBe(true);
        });
      });
    });

    describe('after split button emitted showCreateIssueForm event', () => {
      it('shows create item form', () => {
        expect(findCreateIssueForm().exists()).toBe(false);

        return showCreateIssueForm().then(() => {
          const form = findCreateIssueForm();

          expect(form.exists()).toBe(true);
          expect(form.props().projects).toBe(mockProjects);
        });
      });
    });

    describe('after create issue form emitted cancel event', () => {
      beforeEach(() => showCreateIssueForm());

      it('hides the form', () => {
        expect(findCreateIssueForm().exists()).toBe(true);

        findCreateIssueForm().vm.$emit('cancel');

        return wrapper.vm.$nextTick().then(() => {
          expect(findCreateIssueForm().exists()).toBe(false);
        });
      });
    });

    describe('after create issue form emitted submit event', () => {
      beforeEach(() => showCreateIssueForm());

      it('dispatches createNewIssue action', () => {
        const issuesEndpoint = `${TEST_HOST}/issues`;
        axiosMock.onPost(issuesEndpoint).replyOnce(200, {});

        const params = {
          issuesEndpoint,
          title: 'some new issue',
        };
        findCreateIssueForm().vm.$emit('submit', params);

        return axios.waitFor(issuesEndpoint).then(({ data }) => {
          expect(JSON.parse(data).title).toBe(params.title);
        });
      });
    });
  });
});
