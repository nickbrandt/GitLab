import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import AlertsServiceForm from 'ee/alerts_service_settings/components/alerts_service_form.vue';
import ToggleButton from '~/vue_shared/components/toggle_button.vue';
import createFlash from '~/flash';

jest.mock('~/flash');

const localVue = createLocalVue();

const defaultProps = {
  initialAuthorizationKey: 'abcedfg123',
  formPath: 'http://invalid',
  url: 'https://gitlab.com/endpoint-url',
  learnMoreUrl: 'example.com/learn-more',
  initialActivated: false,
};

describe('AlertsServiceForm', () => {
  let wrapper;
  let mockAxios;

  const createComponent = (props = defaultProps, { methods } = {}) => {
    wrapper = shallowMount(localVue.extend(AlertsServiceForm), {
      localVue,
      propsData: {
        ...defaultProps,
        ...props,
      },
      methods,
    });
  };

  const findUrl = () => wrapper.find('#url');
  const findAuthorizationKey = () => wrapper.find('#authorization-key');
  const findDescription = () => wrapper.find('p');

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    mockAxios.restore();
  });

  describe('with default values', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders "url" input', () => {
      expect(findUrl().html()).toMatchSnapshot();
    });

    it('renders "authorization-key" input', () => {
      expect(findAuthorizationKey().html()).toMatchSnapshot();
    });

    it('renders toggle button', () => {
      expect(wrapper.find(ToggleButton).html()).toMatchSnapshot();
    });

    it('shows description and "Learn More" link', () => {
      expect(findDescription().element.innerHTML).toMatchSnapshot();
    });
  });

  describe('without learnMoreUrl', () => {
    beforeEach(() => {
      createComponent({ learnMoreUrl: '' });
    });

    it('shows description but not "Learn More" link', () => {
      expect(findDescription().element.innerHTML).toMatchSnapshot();
    });
  });

  describe('reset key', () => {
    it('triggers resetKey method', () => {
      const resetKey = jest.fn();
      const methods = { resetKey };
      createComponent(defaultProps, { methods });

      wrapper.find(GlModal).vm.$emit('ok');

      expect(resetKey).toHaveBeenCalled();
    });

    it('updates the authorization key on success', () => {
      const formPath = 'some/path';
      mockAxios.onPut(formPath, { service: { token: '' } }).replyOnce(200, { token: 'newToken' });

      createComponent({ formPath });

      return wrapper.vm.resetKey().then(() => {
        expect(findAuthorizationKey().attributes('value')).toBe('newToken');
      });
    });

    it('shows flash message on error', () => {
      const formPath = 'some/path';
      mockAxios.onPut(formPath).replyOnce(404);

      createComponent({ formPath });

      return wrapper.vm.resetKey().then(() => {
        expect(findAuthorizationKey().attributes('value')).toBe(
          defaultProps.initialAuthorizationKey,
        );
        expect(createFlash).toHaveBeenCalled();
      });
    });
  });

  describe('activate toggle', () => {
    it('triggers toggleActivated method', () => {
      const toggleActivated = jest.fn();
      const methods = { toggleActivated };
      createComponent(defaultProps, { methods });

      wrapper.find(ToggleButton).vm.$emit('change', true);

      expect(toggleActivated).toHaveBeenCalled();
    });

    describe('successfully completes', () => {
      const formPath = 'some/path';

      it('enables toggle when initialActivated=false', () => {
        mockAxios.onPut(formPath, { service: { active: true } }).replyOnce(200, { active: true });
        createComponent({ initialActivated: false, formPath });

        return wrapper.vm.toggleActivated(true).then(() => {
          expect(wrapper.find(ToggleButton).props('value')).toBe(true);
        });
      });

      it('disables toggle when initialActivated=true', () => {
        mockAxios.onPut(formPath, { service: { active: false } }).replyOnce(200, { active: false });
        createComponent({ initialActivated: true, formPath });

        return wrapper.vm.toggleActivated(false).then(() => {
          expect(wrapper.find(ToggleButton).props('value')).toBe(false);
        });
      });
    });

    describe('error is encountered', () => {
      beforeEach(() => {
        const formPath = 'some/path';
        mockAxios.onPut(formPath).replyOnce(500);
      });

      it('restores previous value', () => {
        createComponent({ initialActivated: false });

        return wrapper.vm.toggleActivated(true).then(() => {
          expect(wrapper.find(ToggleButton).props('value')).toBe(false);
        });
      });
    });
  });
});
