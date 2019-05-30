import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import ApprovalsAuth from 'ee/vue_merge_request_widget/components/approvals/approvals_auth.vue';

const TEST_PASSWORD = 'password';

const localVue = createLocalVue();

// For some reason, the `localVue.nextTick` needs to be deferred
// or the timing doesn't work.
const tick = () => Promise.resolve().then(localVue.nextTick);
const waitForTick = done =>
  tick()
    .then(done)
    .catch(done.fail);

describe('Approval auth component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(localVue.extend(ApprovalsAuth), {
      propsData: {
        ...props,
      },
      localVue,
      sync: false,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findConfirm = () => wrapper.find('.js-confirm');
  const findCancel = () => wrapper.find('.js-cancel');
  const findLoading = () => findConfirm().find(GlLoadingIcon);
  const findInput = () => wrapper.find('input[type=password]');
  const findErrorMessage = () => wrapper.find('.gl-field-error');

  describe('when created', () => {
    beforeEach(done => {
      createComponent();
      waitForTick(done);
    });

    it('approve button, cancel button, and password input controls are rendered', () => {
      expect(findConfirm().exists()).toBe(true);
      expect(findCancel().exists()).toBe(true);
      expect(wrapper.find('input').exists()).toBe(true);
    });

    it('does not show loading icon', () => {
      expect(findLoading().exists()).toBe(false);
    });

    it('does not show error message', () => {
      expect(findErrorMessage().exists()).toBe(false);
    });

    it('does not emit anything', () => {
      expect(wrapper.emittedByOrder()).toEqual([]);
    });
  });

  describe('when approve clicked', () => {
    beforeEach(done => {
      createComponent();
      findInput().setValue(TEST_PASSWORD);
      findConfirm().vm.$emit('click');
      waitForTick(done);
    });

    it('emits the approve event', () => {
      expect(wrapper.emittedByOrder()).toEqual([{ name: 'approve', args: [TEST_PASSWORD] }]);
    });
  });

  describe('when cancel is clicked', () => {
    beforeEach(done => {
      createComponent();
      findCancel().vm.$emit('click');
      waitForTick(done);
    });

    it('emits the cancel event', () => {
      expect(wrapper.emittedByOrder()).toEqual([{ name: 'cancel', args: [] }]);
    });
  });

  describe('when isApproving is true', () => {
    beforeEach(done => {
      createComponent({ isApproving: true });
      waitForTick(done);
    });

    it('shows loading icon when isApproving is true', () => {
      expect(findLoading().exists()).toBe(true);
    });
  });

  describe('when hasError is true', () => {
    beforeEach(done => {
      createComponent({ hasError: true });
      waitForTick(done);
    });

    it('shows the invalid password message', () => {
      expect(findErrorMessage().exists()).toBe(true);
    });
  });
});
