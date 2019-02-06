import { shallowMount, createLocalVue } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import ResetKey from 'ee/prometheus_alerts/components/reset_key.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { GlModal } from '@gitlab/ui';

describe('ResetKey', () => {
  let Component;
  let mock;
  let vm;
  const localVue = createLocalVue();

  const propsData = {
    initialAuthorizationKey: 'abcd1234',
    changeKeyUrl: '/updateKeyUrl',
    notifyUrl: '/root/autodevops-deploy/prometheus/alerts/notify.json',
    learnMoreUrl: '/learnMore',
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    Component = localVue.extend(ResetKey);
    setFixtures('<div class="flash-container"></div><div id="reset-key"></div>');
  });

  afterEach(() => {
    mock.restore();
    vm.destroy();
  });

  describe('authorization key exists', () => {
    beforeEach(() => {
      propsData.initialAuthorizationKey = 'abcd1234';
      vm = shallowMount(Component, {
        propsData,
      });
    });

    it('shows fields and buttons', () => {
      expect(vm.find('#notify-url').attributes('value')).toEqual(propsData.notifyUrl);
      expect(vm.find('#authorization-key').attributes('value')).toEqual(
        propsData.initialAuthorizationKey,
      );

      expect(vm.findAll(ClipboardButton).length).toBe(2);
      expect(vm.find('.js-reset-auth-key').text()).toEqual('Reset key');
    });

    it('reset updates key', done => {
      mock.onPost(propsData.changeKeyUrl).replyOnce(200, { token: 'newToken' });

      vm.find(GlModal).vm.$emit('ok');

      setTimeout(() => {
        expect(vm.find('#authorization-key').attributes('value')).toEqual('newToken');
        done();
      });
    });

    it('reset key failure shows error', done => {
      mock.onPost(propsData.changeKeyUrl).replyOnce(500);

      vm.find(GlModal).vm.$emit('ok');

      setTimeout(() => {
        expect(vm.find('#authorization-key').attributes('value')).toEqual(
          propsData.initialAuthorizationKey,
        );

        expect(document.querySelector('.flash-container').innerText.trim()).toEqual(
          'Failed to reset key. Please try again.',
        );
        done();
      });
    });
  });

  describe('authorization key has not been set', () => {
    beforeEach(() => {
      propsData.initialAuthorizationKey = '';
      vm = shallowMount(Component, {
        propsData,
      });
    });

    it('shows Generate Key button', () => {
      expect(vm.find('.js-reset-auth-key').text()).toEqual('Generate key');
      expect(vm.find('#authorization-key').attributes('value')).toEqual('');
    });

    it('Generate key button triggers key change', done => {
      mock.onPost(propsData.changeKeyUrl).replyOnce(200, { token: 'newToken' });

      vm.find('.js-reset-auth-key').vm.$emit('click');

      setTimeout(() => {
        expect(vm.find('#authorization-key').attributes('value')).toEqual('newToken');
        done();
      });
    });
  });
});
