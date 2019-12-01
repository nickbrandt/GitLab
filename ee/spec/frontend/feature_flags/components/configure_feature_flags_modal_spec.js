import { shallowMount, createLocalVue } from '@vue/test-utils';
import component from 'ee/feature_flags/components/configure_feature_flags_modal.vue';

const localVue = createLocalVue();

describe('Configure Feature Flags Modal', () => {
  const Component = localVue.extend(component);
  let wrapper;
  let propsData;

  afterEach(() => wrapper.destroy());

  beforeEach(() => {
    propsData = {
      helpPath: '/help/path',
      helpAnchor: '/help/path/#flags',
      apiUrl: '/api/url',
      instanceId: 'instance-id-token',
      isRotating: false,
      hasRotateError: false,
      canUserRotateToken: true,
    };

    wrapper = shallowMount(Component, {
      propsData,
      localVue,
      sync: false,
      attachToDocument: true,
    });
  });

  describe('rotate token', () => {
    it('should emit a `token` event on click', () => {
      wrapper.find('.js-ff-rotate-token-button').trigger('click');
      expect(wrapper.emitted('token')).not.toBeEmpty();
    });

    it('should display an error if there is a rotate error', () => {
      wrapper.setProps({ hasRotateError: true });
      expect(wrapper.find('.text-danger')).toExist();
      expect(wrapper.find('[name="warning"]')).toExist();
    });

    it('should be hidden if the user cannot rotate tokens', () => {
      wrapper.setProps({ canUserRotateToken: false });
      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find('.js-ff-rotate-token-button').exists()).toBe(false);
      });
    });
  });

  describe('instance id', () => {
    it('should be displayed in an input box', () => {
      const input = wrapper.find('#instance_id');
      expect(input.element.value).toBe('instance-id-token');
    });
  });
  describe('api url', () => {
    it('should be displayed in an input box', () => {
      const input = wrapper.find('#api_url');
      expect(input.element.value).toBe('/api/url');
    });
  });
  describe('help text', () => {
    it('should be displayed', () => {
      const help = wrapper.find('p');
      expect(help.text()).toMatch(/More Information/);
    });

    it('should have links to the documentation', () => {
      const help = wrapper.find('p');
      const link = help.find('a[href="/help/path"]');
      expect(link.exists()).toBe(true);
      const anchoredLink = help.find('a[href="/help/path/#flags"]');
      expect(anchoredLink.exists()).toBe(true);
    });
  });
});
