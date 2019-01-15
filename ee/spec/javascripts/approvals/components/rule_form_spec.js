import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlButton } from '@gitlab/ui';
import ApproversSelect from 'ee/approvals/components/approvers_select.vue';
import RuleForm from 'ee/approvals/components/rule_form.vue';
import { TYPE_USER, TYPE_GROUP } from 'ee/approvals/constants';

const TEST_PROJECT_ID = '7';
const TEST_RULE = {
  id: 10,
  name: 'QA',
  approvalsRequired: 2,
  users: [{ id: 1 }, { id: 2 }, { id: 3 }],
  groups: [{ id: 1 }, { id: 2 }],
};

const localVue = createLocalVue();
localVue.use(Vuex);

const wrapInput = node => ({
  node,
  feedback: () => node.element.nextElementSibling.textContent,
  isValid: () => !node.classes('is-invalid'),
});
const findInput = (form, selector) => wrapInput(form.find(selector));
const findNameInput = form => findInput(form, 'input[name=name]');
const findApprovalsRequiredInput = form => findInput(form, 'input[name=approvals_required]');
const findApproversSelect = form => {
  const input = findInput(form, ApproversSelect);

  return {
    ...input,
    isValid() {
      return !input.node.props('isInvalid');
    },
  };
};

describe('Approvals RuleForm', () => {
  let state;
  let actions;
  let wrapper;

  const factory = (options = {}) => {
    const store = new Vuex.Store({
      state,
      actions,
    });

    wrapper = shallowMount(localVue.extend(RuleForm), {
      ...options,
      localVue,
      store,
    });
  };

  beforeEach(() => {
    state = {
      settings: { projectId: TEST_PROJECT_ID },
    };

    actions = {
      postRule: jasmine.createSpy('postRule'),
      putRule: jasmine.createSpy('putRule'),
    };
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('without initRule', () => {
    beforeEach(() => {
      factory();
    });

    it('at first, shows no validation', () => {
      const inputs = [
        findNameInput(wrapper),
        findApprovalsRequiredInput(wrapper),
        findApproversSelect(wrapper),
      ];
      const invalidInputs = inputs.filter(x => !x.isValid());
      const feedbacks = inputs.map(x => x.feedback());

      expect(invalidInputs.length).toBe(0);
      expect(feedbacks.every(str => !str.length)).toBe(true);
    });

    it('on submit, does not dispatch action', () => {
      wrapper.vm.submit();

      expect(actions.postRule).not.toHaveBeenCalled();
    });

    it('on submit, shows name validation', () => {
      const { node, isValid, feedback } = findNameInput(wrapper);
      node.setValue('');

      wrapper.vm.submit();

      expect(isValid()).toBe(false);
      expect(feedback()).toEqual('Please provide a name');
    });

    it('on submit, shows approvalsRequired validation', () => {
      const { node, isValid, feedback } = findApprovalsRequiredInput(wrapper);
      node.setValue(-1);

      wrapper.vm.submit();

      expect(isValid()).toBe(false);
      expect(feedback()).toEqual('Please enter a non-negative number');
    });

    it('on submit, shows approvers validation', () => {
      const { isValid, feedback } = findApproversSelect(wrapper);
      wrapper.vm.approvers = [];

      wrapper.vm.submit();

      expect(isValid()).toBe(false);
      expect(feedback()).toEqual('Please select and add a member');
    });

    it('on submit with data, posts rule', () => {
      const users = [1, 2];
      const groups = [2, 3];
      const userRecords = users.map(id => ({ id, type: TYPE_USER }));
      const groupRecords = groups.map(id => ({ id, type: TYPE_GROUP }));
      const expected = {
        name: 'Lorem',
        approvalsRequired: 2,
        users,
        groups,
        userRecords,
        groupRecords,
      };
      const name = findNameInput(wrapper);
      const approvalsRequired = findApprovalsRequiredInput(wrapper);

      name.node.setValue(expected.name);
      approvalsRequired.node.setValue(expected.approvalsRequired);
      wrapper.vm.approvers = groupRecords.concat(userRecords);

      wrapper.vm.submit();

      expect(actions.postRule).toHaveBeenCalledWith(jasmine.anything(), expected, undefined);
    });

    it('adds selected approvers on button click', () => {
      const { node } = findApproversSelect(wrapper);
      const selected = [
        { id: 1, type: TYPE_USER },
        { id: 2, type: TYPE_USER },
        { id: 1, type: TYPE_GROUP },
      ];
      const orig = [{ id: 7, type: TYPE_GROUP }];
      const expected = selected.concat(orig);

      wrapper.vm.approvers = orig;

      node.vm.$emit('input', selected);
      wrapper.find(GlButton).vm.$emit('click');

      expect(wrapper.vm.approvers).toEqual(expected);
    });
  });

  describe('with initRule', () => {
    beforeEach(() => {
      factory({
        propsData: {
          initRule: TEST_RULE,
        },
      });
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
      };

      wrapper.vm.submit();

      expect(actions.putRule).toHaveBeenCalledWith(jasmine.anything(), expected, undefined);
    });
  });
});
