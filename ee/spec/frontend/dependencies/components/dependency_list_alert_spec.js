import { createLocalVue, shallowMount } from '@vue/test-utils';
import { WARNING } from 'ee/dependencies/components/constants';
import DependencyListAlert from 'ee/dependencies/components/dependency_list_alert.vue';

describe('DependencyListAlert component', () => {
  let wrapper;

  const factory = (props = {}) => {
    const localVue = createLocalVue();

    wrapper = shallowMount(localVue.extend(DependencyListAlert), {
      localVue,
      sync: false,
      propsData: { ...props },
      slots: {
        default: '<p>foo <span>bar</span></p>',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('given no props', () => {
    beforeEach(() => {
      factory();
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('given the warning type and headerText props', () => {
    beforeEach(() => {
      factory({ type: WARNING, headerText: 'Some header' });
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('given the headerText prop', () => {
    beforeEach(() => {
      factory({ headerText: 'A header' });
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('clicking on the close button', () => {
    beforeEach(() => {
      factory();
      wrapper.find('.js-close').vm.$emit('click');
      return wrapper.vm.$nextTick();
    });

    it('emits the close event', () => {
      expect(wrapper.emitted().close.length).toBe(1);
    });
  });
});
