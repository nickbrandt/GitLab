import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { createStoreOptions } from 'ee/approvals/stores';
import projectSettingsModule from 'ee/approvals/stores/modules/project_settings';
import ApproversSelect from 'ee/approvals/components/approvers_select.vue';
import ApproversList from 'ee/approvals/components/approvers_list.vue';
import RuleForm from 'ee/approvals/components/rule_form.vue';
import { TYPE_USER, TYPE_GROUP, TYPE_HIDDEN_GROUPS } from 'ee/approvals/constants';

const TEST_PROJECT_ID = '7';
const TEST_RULE = {
  id: 10,
  name: 'QA',
  approvalsRequired: 2,
  users: [{ id: 1 }, { id: 2 }, { id: 3 }],
  groups: [{ id: 1 }, { id: 2 }],
};
const TEST_APPROVERS = [{ id: 7, type: TYPE_USER }];
const TEST_APPROVALS_REQUIRED = 3;
const TEST_FALLBACK_RULE = {
  approvalsRequired: 1,
  isFallback: true,
};

const localVue = createLocalVue();
localVue.use(Vuex);

const addType = type => x => Object.assign(x, { type });

describe('EE Approvals RuleForm', () => {
  let wrapper;
  let store;
  let actions;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(localVue.extend(RuleForm), {
      propsData: props,
      store: new Vuex.Store(store),
      localVue,
    });
  };
  const findValidation = (node, hasProps = false) => ({
    feedback: node.element.nextElementSibling.textContent,
    isValid: hasProps ? !node.props('isInvalid') : !node.classes('is-invalid'),
  });
  const findNameInput = () => wrapper.find('input[name=name]');
  const findNameValidation = () => findValidation(findNameInput(), false);
  const findApprovalsRequiredInput = () => wrapper.find('input[name=approvals_required]');
  const findApprovalsRequiredValidation = () => findValidation(findApprovalsRequiredInput(), false);
  const findApproversSelect = () => wrapper.find(ApproversSelect);
  const findApproversValidation = () => findValidation(findApproversSelect(), true);
  const findApproversList = () => wrapper.find(ApproversList);
  const findValidations = () => [
    findNameValidation(),
    findApprovalsRequiredValidation(),
    findApproversValidation(),
  ];

  beforeEach(() => {
    store = createStoreOptions(projectSettingsModule(), { projectId: TEST_PROJECT_ID });

    ['postRule', 'putRule', 'deleteRule', 'putFallbackRule'].forEach(actionName => {
      spyOn(store.modules.approvals.actions, actionName);
    });

    ({ actions } = store.modules.approvals);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when allow multiple rules', () => {
    beforeEach(() => {
      store.state.settings.allowMultiRule = true;
    });

    describe('without initRule', () => {
      beforeEach(() => {
        createComponent();
      });

      it('at first, shows no validation', () => {
        const inputs = findValidations();
        const invalidInputs = inputs.filter(x => !x.isValid);
        const feedbacks = inputs.map(x => x.feedback);

        expect(invalidInputs.length).toBe(0);
        expect(feedbacks.every(str => !str.length)).toBe(true);
      });

      it('on submit, does not dispatch action', () => {
        wrapper.vm.submit();

        expect(actions.postRule).not.toHaveBeenCalled();
      });

      it('on submit, shows name validation', done => {
        findNameInput().setValue('');

        wrapper.vm.submit();

        localVue
          .nextTick()
          .then(() => {
            expect(findNameValidation()).toEqual({
              isValid: false,
              feedback: 'Please provide a name',
            });
          })
          .then(done)
          .catch(done.fail);
      });

      it('on submit, shows approvalsRequired validation', done => {
        findApprovalsRequiredInput().setValue(-1);

        wrapper.vm.submit();

        localVue
          .nextTick()
          .then(() => {
            expect(findApprovalsRequiredValidation()).toEqual({
              isValid: false,
              feedback: 'Please enter a non-negative number',
            });
          })
          .then(done)
          .catch(done.fail);
      });

      it('on submit, shows approvers validation', done => {
        wrapper.vm.approvers = [];
        wrapper.vm.submit();

        localVue
          .nextTick()
          .then(() => {
            expect(findApproversValidation()).toEqual({
              isValid: false,
              feedback: 'Please select and add a member',
            });
          })
          .then(done)
          .catch(done.fail);
      });

      it('on submit with data, posts rule', () => {
        const users = [1, 2];
        const groups = [2, 3];
        const userRecords = users.map(id => ({ id, type: TYPE_USER }));
        const groupRecords = groups.map(id => ({ id, type: TYPE_GROUP }));
        const expected = {
          id: null,
          name: 'Lorem',
          approvalsRequired: 2,
          users,
          groups,
          userRecords,
          groupRecords,
          removeHiddenGroups: false,
        };

        findNameInput().setValue(expected.name);
        findApprovalsRequiredInput().setValue(expected.approvalsRequired);
        wrapper.vm.approvers = groupRecords.concat(userRecords);

        wrapper.vm.submit();

        expect(actions.postRule).toHaveBeenCalledWith(jasmine.anything(), expected, undefined);
      });

      it('adds selected approvers on selection', () => {
        const orig = [{ id: 7, type: TYPE_GROUP }];
        const selected = [{ id: 2, type: TYPE_USER }];
        const expected = [...orig, ...selected];

        wrapper.setData({ approvers: orig });
        wrapper.vm.$options.watch.approversToAdd.call(wrapper.vm, selected);

        expect(wrapper.vm.approvers).toEqual(expected);
      });
    });

    describe('with initRule', () => {
      beforeEach(() => {
        createComponent({
          initRule: TEST_RULE,
        });
      });

      it('does not disable the name text field', () => {
        expect(findNameInput().attributes('disabled')).toBe(undefined);
      });

      it('shows approvers', () => {
        const list = findApproversList();

        expect(list.props('value')).toEqual([
          ...TEST_RULE.groups.map(addType(TYPE_GROUP)),
          ...TEST_RULE.users.map(addType(TYPE_USER)),
        ]);
      });

      it('on submit, puts rule', () => {
        const userRecords = TEST_RULE.users.map(x => ({ ...x, type: TYPE_USER }));
        const groupRecords = TEST_RULE.groups.map(x => ({ ...x, type: TYPE_GROUP }));
        const users = userRecords.map(x => x.id);
        const groups = groupRecords.map(x => x.id);

        const expected = {
          ...TEST_RULE,
          users,
          groups,
          userRecords,
          groupRecords,
          removeHiddenGroups: false,
        };

        wrapper.vm.submit();

        expect(actions.putRule).toHaveBeenCalledWith(jasmine.anything(), expected, undefined);
      });
    });

    describe('with init fallback rule', () => {
      beforeEach(() => {
        createComponent({
          initRule: TEST_FALLBACK_RULE,
        });

        wrapper.vm.name = '';
        wrapper.vm.approvers = [];
        wrapper.vm.approvalsRequired = TEST_APPROVALS_REQUIRED;
      });

      describe('with empty name and empty approvers', () => {
        beforeEach(done => {
          wrapper.vm.submit();
          localVue.nextTick(done);
        });

        it('does not post rule', () => {
          expect(actions.postRule).not.toHaveBeenCalled();
        });

        it('puts fallback rule', () => {
          expect(actions.putFallbackRule).toHaveBeenCalledWith(
            jasmine.anything(),
            { approvalsRequired: TEST_APPROVALS_REQUIRED },
            undefined,
          );
        });

        it('does not show any validation errors', () => {
          expect(findValidations().every(x => x.isValid)).toBe(true);
        });
      });

      describe('with name and empty approvers', () => {
        beforeEach(done => {
          wrapper.vm.name = 'Lorem';
          wrapper.vm.submit();

          localVue.nextTick(done);
        });

        it('does not put fallback rule', () => {
          expect(actions.putFallbackRule).not.toHaveBeenCalled();
        });

        it('shows approvers validation error', () => {
          expect(findApproversValidation().isValid).toBe(false);
        });
      });

      describe('with empty name and approvers', () => {
        beforeEach(done => {
          wrapper.vm.approvers = TEST_APPROVERS;
          wrapper.vm.submit();

          localVue.nextTick(done);
        });

        it('does not put fallback rule', () => {
          expect(actions.putFallbackRule).not.toHaveBeenCalled();
        });

        it('shows name validation error', () => {
          expect(findNameValidation().isValid).toBe(false);
        });
      });

      describe('with name and approvers', () => {
        beforeEach(done => {
          wrapper.vm.approvers = [{ id: 7, type: TYPE_USER }];
          wrapper.vm.name = 'Lorem';
          wrapper.vm.submit();

          localVue.nextTick(done);
        });

        it('does not put fallback rule', () => {
          expect(actions.putFallbackRule).not.toHaveBeenCalled();
        });

        it('posts new rule', () => {
          expect(actions.postRule).toHaveBeenCalled();
        });
      });
    });

    describe('with hidden groups rule', () => {
      beforeEach(() => {
        createComponent({
          initRule: {
            ...TEST_RULE,
            containsHiddenGroups: true,
          },
        });
      });

      it('shows approvers and hidden group', () => {
        const list = findApproversList();

        expect(list.props('value')).toEqual([
          ...TEST_RULE.groups.map(addType(TYPE_GROUP)),
          ...TEST_RULE.users.map(addType(TYPE_USER)),
          { type: TYPE_HIDDEN_GROUPS },
        ]);
      });

      it('on submit, does not remove hidden groups', () => {
        wrapper.vm.submit();

        expect(actions.putRule).toHaveBeenCalledWith(
          jasmine.anything(),
          jasmine.objectContaining({
            removeHiddenGroups: false,
          }),
          undefined,
        );
      });

      describe('and hidden groups removed', () => {
        beforeEach(() => {
          wrapper.vm.approvers = wrapper.vm.approvers.filter(x => x.type !== TYPE_HIDDEN_GROUPS);
        });

        it('on submit, removes hidden groups', () => {
          wrapper.vm.submit();

          expect(actions.putRule).toHaveBeenCalledWith(
            jasmine.anything(),
            jasmine.objectContaining({
              removeHiddenGroups: true,
            }),
            undefined,
          );
        });
      });
    });

    describe('with removed hidden groups rule', () => {
      beforeEach(() => {
        createComponent({
          initRule: {
            ...TEST_RULE,
            containsHiddenGroups: true,
            removeHiddenGroups: true,
          },
        });
      });

      it('does not add hidden groups in approvers', () => {
        expect(
          findApproversList()
            .props('value')
            .every(x => x.type !== TYPE_HIDDEN_GROUPS),
        ).toBe(true);
      });
    });

    describe('with new License-Check rule', () => {
      beforeEach(() => {
        createComponent({
          initRule: { ...TEST_RULE, id: null, name: 'License-Check' },
        });
      });

      it('does not disable the name text field', () => {
        expect(findNameInput().attributes('disabled')).toBe(undefined);
      });
    });

    describe('with editing the License-Check rule', () => {
      beforeEach(() => {
        createComponent({
          initRule: { ...TEST_RULE, name: 'License-Check' },
        });
      });

      it('disables the name text field', () => {
        expect(findNameInput().attributes('disabled')).toBe('disabled');
      });
    });
  });

  describe('when allow only single rule', () => {
    beforeEach(() => {
      store.state.settings.allowMultiRule = false;
    });

    it('hides name', () => {
      createComponent();

      expect(findNameInput().exists()).toBe(true);
    });

    describe('with no init rule', () => {
      beforeEach(() => {
        createComponent();
        wrapper.vm.approvalsRequired = TEST_APPROVALS_REQUIRED;
      });

      describe('with approvers selected', () => {
        beforeEach(done => {
          wrapper.vm.approvers = TEST_APPROVERS;
          wrapper.vm.submit();

          localVue.nextTick(done);
        });

        it('posts new rule', () => {
          expect(actions.postRule).toHaveBeenCalledWith(
            jasmine.anything(),
            jasmine.objectContaining({
              approvalsRequired: TEST_APPROVALS_REQUIRED,
              users: TEST_APPROVERS.map(x => x.id),
            }),
            undefined,
          );
        });
      });

      describe('without approvers', () => {
        beforeEach(done => {
          wrapper.vm.submit();

          localVue.nextTick(done);
        });

        it('puts fallback rule', () => {
          expect(actions.putFallbackRule).toHaveBeenCalledWith(
            jasmine.anything(),
            { approvalsRequired: TEST_APPROVALS_REQUIRED },
            undefined,
          );
        });
      });
    });

    describe('with init rule', () => {
      beforeEach(() => {
        createComponent({
          initRule: TEST_RULE,
        });
        wrapper.vm.approvalsRequired = TEST_APPROVALS_REQUIRED;
      });

      describe('with empty name and empty approvers', () => {
        beforeEach(done => {
          wrapper.vm.name = '';
          wrapper.vm.approvers = [];
          wrapper.vm.submit();

          localVue.nextTick(done);
        });

        it('deletes rule', () => {
          expect(actions.deleteRule).toHaveBeenCalledWith(
            jasmine.anything(),
            TEST_RULE.id,
            undefined,
          );
        });

        it('puts fallback rule', () => {
          expect(actions.putFallbackRule).toHaveBeenCalledWith(
            jasmine.anything(),
            { approvalsRequired: TEST_APPROVALS_REQUIRED },
            undefined,
          );
        });
      });

      describe('with name and approvers', () => {
        beforeEach(done => {
          wrapper.vm.name = 'Bogus';
          wrapper.vm.approvers = TEST_APPROVERS;
          wrapper.vm.submit();

          localVue.nextTick(done);
        });

        it('puts rule', () => {
          expect(actions.putRule).toHaveBeenCalledWith(
            jasmine.anything(),
            jasmine.objectContaining({
              id: TEST_RULE.id,
              name: 'Bogus',
              approvalsRequired: TEST_APPROVALS_REQUIRED,
              users: TEST_APPROVERS.map(x => x.id),
            }),
            undefined,
          );
        });
      });
    });
  });
});
