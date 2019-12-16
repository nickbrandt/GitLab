import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';

import RelatedItemsTreeApp from 'ee/related_items_tree/components/related_items_tree_app.vue';
import RelatedItemsTreeHeader from 'ee/related_items_tree/components/related_items_tree_header.vue';
import createDefaultStore from 'ee/related_items_tree/store';
import { issuableTypesMap } from 'ee/related_issues/constants';
import AddItemForm from 'ee/related_issues/components/add_issuable_form.vue';
import CreateIssueForm from 'ee/related_items_tree/components/create_issue_form.vue';
import IssueActionsSplitButton from 'ee/related_items_tree/components/issue_actions_split_button.vue';
import { TEST_HOST } from 'spec/test_constants';

import { mockInitialConfig, mockParentItem } from '../mock_data';

const localVue = createLocalVue();

const createComponent = () => {
  const store = createDefaultStore();

  store.dispatch('setInitialConfig', mockInitialConfig);
  store.dispatch('setInitialParentItem', mockParentItem);

  return shallowMount(localVue.extend(RelatedItemsTreeApp), {
    localVue,
    store,
    sync: false,
  });
};

describe('RelatedItemsTreeApp', () => {
  let wrapper;

  const findAddItemForm = () => wrapper.find(AddItemForm);
  const findCreateIssueForm = () => wrapper.find(CreateIssueForm);
  const findIssueActionsSplitButton = () => wrapper.find(IssueActionsSplitButton);

  afterEach(() => {
    wrapper.destroy();
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
        spyOn(wrapper.vm, 'removePendingReference');

        wrapper.vm.handlePendingItemRemove(0);

        expect(wrapper.vm.removePendingReference).toHaveBeenCalledWith(0);
      });
    });

    describe('handleAddItemFormInput', () => {
      const untouchedRawReferences = ['&1'];
      const touchedReference = '&2';

      it('calls `addPendingReferences` action with provided `untouchedRawReferences` param', () => {
        spyOn(wrapper.vm, 'addPendingReferences');

        wrapper.vm.handleAddItemFormInput({ untouchedRawReferences, touchedReference });

        expect(wrapper.vm.addPendingReferences).toHaveBeenCalledWith(untouchedRawReferences);
      });

      it('calls `setItemInputValue` action with provided `touchedReference` param', () => {
        spyOn(wrapper.vm, 'setItemInputValue');

        wrapper.vm.handleAddItemFormInput({ untouchedRawReferences, touchedReference });

        expect(wrapper.vm.setItemInputValue).toHaveBeenCalledWith(touchedReference);
      });
    });

    describe('handleAddItemFormBlur', () => {
      const newValue = '&1 &2';

      it('calls `addPendingReferences` action with provided `newValue` param', () => {
        spyOn(wrapper.vm, 'addPendingReferences');

        wrapper.vm.handleAddItemFormBlur(newValue);

        expect(wrapper.vm.addPendingReferences).toHaveBeenCalledWith(newValue.split(/\s+/));
      });

      it('calls `setItemInputValue` action with empty string', () => {
        spyOn(wrapper.vm, 'setItemInputValue');

        wrapper.vm.handleAddItemFormBlur(newValue);

        expect(wrapper.vm.setItemInputValue).toHaveBeenCalledWith('');
      });
    });

    describe('handleAddItemFormSubmit', () => {
      it('calls `addItem` action when `pendingReferences` prop in state is not empty', () => {
        const newValue = '&1 &2';
        spyOn(wrapper.vm, 'addItem');

        wrapper.vm.handleAddItemFormSubmit(newValue);

        expect(wrapper.vm.addItem).toHaveBeenCalled();
      });
    });

    describe('handleCreateEpicFormSubmit', () => {
      it('calls `createItem` action with `itemTitle` param', () => {
        const newValue = 'foo';
        spyOn(wrapper.vm, 'createItem');

        wrapper.vm.handleCreateEpicFormSubmit(newValue);

        expect(wrapper.vm.createItem).toHaveBeenCalledWith({
          itemTitle: newValue,
        });
      });
    });

    describe('handleAddItemFormCancel', () => {
      it('calls `toggleAddItemForm` actions with params `toggleState` as `false`', () => {
        spyOn(wrapper.vm, 'toggleAddItemForm');

        wrapper.vm.handleAddItemFormCancel();

        expect(wrapper.vm.toggleAddItemForm).toHaveBeenCalledWith({ toggleState: false });
      });

      it('calls `setPendingReferences` action with empty array', () => {
        spyOn(wrapper.vm, 'setPendingReferences');

        wrapper.vm.handleAddItemFormCancel();

        expect(wrapper.vm.setPendingReferences).toHaveBeenCalledWith([]);
      });

      it('calls `setItemInputValue` action with empty string', () => {
        spyOn(wrapper.vm, 'setItemInputValue');

        wrapper.vm.handleAddItemFormCancel();

        expect(wrapper.vm.setItemInputValue).toHaveBeenCalledWith('');
      });
    });

    describe('handleCreateEpicFormCancel', () => {
      it('calls `toggleCreateEpicForm` actions with params `toggleState`', () => {
        spyOn(wrapper.vm, 'toggleCreateEpicForm');

        wrapper.vm.handleCreateEpicFormCancel();

        expect(wrapper.vm.toggleCreateEpicForm).toHaveBeenCalledWith({ toggleState: false });
      });

      it('calls `setItemInputValue` action with empty string', () => {
        spyOn(wrapper.vm, 'setItemInputValue');

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

    it('renders loading icon when `state.itemsFetchInProgress` prop is true', done => {
      wrapper.vm.$store.dispatch('requestItems', {
        parentItem: mockParentItem,
        isSubItem: false,
      });

      wrapper.vm.$nextTick(() => {
        expect(wrapper.find(GlLoadingIcon).isVisible()).toBe(true);
        done();
      });
    });

    it('renders tree container element when `state.itemsFetchInProgress` prop is false', done => {
      wrapper.vm.$nextTick(() => {
        expect(wrapper.find('.related-items-tree').isVisible()).toBe(true);
        done();
      });
    });

    it('renders tree container element with `disabled-content` class when `state.itemsFetchInProgress` prop is false and `state.itemAddInProgress` or `state.itemCreateInProgress` is true', done => {
      wrapper.vm.$store.dispatch('requestAddItem');

      wrapper.vm.$nextTick(() => {
        expect(wrapper.find('.related-items-tree.disabled-content').isVisible()).toBe(true);
        done();
      });
    });

    it('renders tree header component', done => {
      wrapper.vm.$nextTick(() => {
        expect(wrapper.find(RelatedItemsTreeHeader).isVisible()).toBe(true);
        done();
      });
    });

    it('renders item add/create form container element', done => {
      wrapper.vm.$store.dispatch('toggleAddItemForm', {
        toggleState: true,
        issuableType: issuableTypesMap.Epic,
      });

      wrapper.vm.$nextTick(() => {
        expect(wrapper.find('.add-item-form-container').isVisible()).toBe(true);
        done();
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
    beforeEach(done => {
      window.gon.features = { epicNewIssue: true };
      wrapper = createComponent();
      wrapper.vm.$store.state.itemsFetchInProgress = false;
      wrapper.vm
        .$nextTick()
        .then(done)
        .catch(done.fail);
    });

    afterEach(() => {
      window.gon.features = {};
    });

    it('renders issue actions split button', () => {
      expect(findIssueActionsSplitButton().exists()).toBe(true);
    });

    describe('after split button emitted showAddIssueForm event', () => {
      it('shows add item form', done => {
        expect(findAddItemForm().exists()).toBe(false);

        findIssueActionsSplitButton().vm.$emit('showAddIssueForm');

        wrapper.vm
          .$nextTick()
          .then(() => {
            expect(findAddItemForm().exists()).toBe(true);
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('after split button emitted showCreateIssueForm event', () => {
      it('shows create item form', done => {
        expect(findCreateIssueForm().exists()).toBe(false);

        findIssueActionsSplitButton().vm.$emit('showCreateIssueForm');

        wrapper.vm
          .$nextTick()
          .then(() => {
            const form = findCreateIssueForm();

            expect(form.exists()).toBe(true);
            expect(form.props().projectsEndpoint).toBe(mockInitialConfig.projectsEndpoint);
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('after create issue form emitted cancel event', () => {
      beforeEach(done => {
        findIssueActionsSplitButton().vm.$emit('showCreateIssueForm');

        wrapper.vm
          .$nextTick()
          .then(done)
          .catch(done.fail);
      });

      it('hides the form', done => {
        expect(findCreateIssueForm().exists()).toBe(true);

        findCreateIssueForm().vm.$emit('cancel');

        wrapper.vm
          .$nextTick()
          .then(() => {
            expect(findCreateIssueForm().exists()).toBe(false);
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('after create issue form emitted submit event', () => {
      beforeEach(done => {
        findIssueActionsSplitButton().vm.$emit('showCreateIssueForm');

        wrapper.vm
          .$nextTick()
          .then(done)
          .catch(done.fail);
      });

      it('dispatches createNewIssue action', () => {
        const createNewIssue = jasmine.createSpy('createNewIssue');
        const store = wrapper.vm.$store;
        store.hotUpdate({
          actions: {
            createNewIssue: (context, payload) => createNewIssue(payload),
          },
        });

        const params = {
          issuesEndpoint: `${TEST_HOST}/issues`,
          title: 'some new issue',
        };
        findCreateIssueForm().vm.$emit('submit', params);

        expect(createNewIssue).toHaveBeenCalledWith(params);
      });
    });
  });
});
