import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import createStore from 'ee/subscriptions/new/store';
import * as constants from 'ee/subscriptions/new/constants';
import component from 'ee/subscriptions/new/components/checkout/components/step.vue';
import StepSummary from 'ee/subscriptions/new/components/checkout/components/step_summary.vue';

describe('Step', () => {
  const localVue = createLocalVue();
  localVue.use(Vuex);

  let wrapper;

  const store = createStore();

  const initialProps = {
    step: 'secondStep',
    isValid: true,
    title: 'title',
    nextStepButtonText: 'next',
  };

  const factory = propsData => {
    wrapper = shallowMount(component, {
      store,
      propsData: { ...initialProps, ...propsData },
      localVue,
    });
  };

  const activatePreviousStep = () => {
    store.dispatch('activateStep', 'firstStep');
  };

  constants.STEPS = ['firstStep', 'secondStep'];

  beforeEach(() => {
    store.dispatch('activateStep', 'secondStep');
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Step Body', () => {
    it('should display the step body when this step is the current step', () => {
      factory();

      expect(wrapper.find('.card > div').attributes('style')).toBeUndefined();
    });

    it('should not display the step body when this step is not the current step', () => {
      activatePreviousStep();
      factory();

      expect(wrapper.find('.card > div').attributes('style')).toBe('display: none;');
    });
  });

  describe('Step Summary', () => {
    it('should be shown when this step is valid and not active', () => {
      activatePreviousStep();
      factory();

      expect(wrapper.find(StepSummary).exists()).toBe(true);
    });

    it('should not be shown when this step is not valid and not active', () => {
      activatePreviousStep();
      factory({ isValid: false });

      expect(wrapper.find(StepSummary).exists()).toBe(false);
    });

    it('should not be shown when this step is valid and active', () => {
      factory();

      expect(wrapper.find(StepSummary).exists()).toBe(false);
    });

    it('should not be shown when this step is not valid and active', () => {
      factory({ isValid: false });

      expect(wrapper.find(StepSummary).exists()).toBe(false);
    });
  });

  describe('isEditable', () => {
    it('should set the isEditable property to true when this step is finished and comes before the current step', () => {
      factory({ step: 'firstStep' });

      expect(wrapper.find(StepSummary).props('isEditable')).toBe(true);
    });
  });

  describe('Showing the summary', () => {
    it('shows the summary when this step is finished', () => {
      activatePreviousStep();
      factory();

      expect(wrapper.find(StepSummary).exists()).toBe(true);
    });

    it('does not show the summary when this step is not finished', () => {
      factory();

      expect(wrapper.find(StepSummary).exists()).toBe(false);
    });
  });

  describe('Next button', () => {
    it('shows the next button when the text was passed', () => {
      factory();

      expect(wrapper.text()).toBe('next');
    });

    it('does not show the next button when no text was passed', () => {
      factory({ nextStepButtonText: '' });

      expect(wrapper.text()).toBe('');
    });

    it('is disabled when this step is not valid', () => {
      factory({ isValid: false });

      expect(wrapper.find(GlButton).attributes('disabled')).toBe('true');
    });

    it('is enabled when this step is valid', () => {
      factory();

      expect(wrapper.find(GlButton).attributes('disabled')).toBeUndefined();
    });
  });
});
