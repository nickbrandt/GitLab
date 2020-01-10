import { shallowMount } from '@vue/test-utils';
import component from 'ee/subscriptions/new/components/checkout/progress_bar.vue';

describe('Progress Bar', () => {
  let wrapper;

  const factory = propsData => {
    wrapper = shallowMount(component, {
      propsData,
    });
  };

  const firstStep = () => wrapper.find('.bar div:nth-child(1)');
  const secondStep = () => wrapper.find('.bar div:nth-child(2)');

  beforeEach(() => {
    factory({ step: 2 });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('current', () => {
    it('step 1 is not current', () => {
      expect(firstStep().classes()).not.toContain('current');
    });

    it('step 2 is current', () => {
      expect(secondStep().classes()).toContain('current');
    });
  });

  describe('finished', () => {
    it('step 1 is finished', () => {
      expect(firstStep().classes()).toContain('finished');
    });

    it('step 2 is not finished', () => {
      expect(secondStep().classes()).not.toContain('finished');
    });
  });
});
