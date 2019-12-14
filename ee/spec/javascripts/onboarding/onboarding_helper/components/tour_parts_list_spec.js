import component from 'ee/onboarding/onboarding_helper/components/tour_parts_list.vue';
import { shallowMount, createLocalVue } from '@vue/test-utils';

const localVue = createLocalVue();

describe('User onboarding tour parts list', () => {
  let wrapper;

  const tourTitles = [
    { id: 1, title: 'First tour' },
    { id: 2, title: 'Second tour' },
    { id: 3, title: 'Yet another tour' },
  ];
  const defaultProps = {
    tourTitles,
    activeTour: 1,
    totalStepsForTour: 10,
    completedSteps: 3,
  };
  let tourItems;

  function createComponent(propsData) {
    wrapper = shallowMount(localVue.extend(component), { propsData, localVue, sync: false });
  }

  beforeEach(() => {
    createComponent(defaultProps);
    tourItems = wrapper.findAll('.tour-item');
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('stepsCompletedInfo', () => {
      it('returns "3/10 steps completed"', () => {
        expect(wrapper.vm.stepsCompletedInfo).toEqual('3/10 steps completed');
      });
    });
  });

  describe('methods', () => {
    describe('isActiveTour', () => {
      it('returns true when the given tour number is active', () => {
        expect(wrapper.vm.isActiveTour(1)).toBeTruthy();
      });

      it('returns false when the given tour number is not active', () => {
        expect(wrapper.vm.isActiveTour(2)).toBeFalsy();
      });
    });
  });

  describe('template', () => {
    it('renders a list item for each tour title', () => {
      expect(wrapper.findAll('.tour-item').length).toEqual(tourTitles.length);
    });

    it('adds the "active" class to the first tour item', () => {
      expect(tourItems.at(0).classes('active')).toEqual(true);
    });

    it('does not add the "active" class to the second tour item', () => {
      expect(tourItems.at(1).classes('active')).toEqual(false);
    });

    it('adds the "text-info" class to the tour title of the first item', () => {
      const tourTitle = tourItems.at(0).find('.tour-title');

      expect(tourTitle.classes('text-info')).toEqual(true);
    });

    it('does not add the "text-info" class to the tour title of the second item', () => {
      const tourTitle = tourItems.at(1).find('.tour-title');

      expect(tourTitle.classes('text-info')).toEqual(false);
    });

    it('renders "3/10 steps completed" below the first tour item', () => {
      const completedInfo = tourItems.at(0).find('.text-secondary');

      expect(completedInfo.exists()).toBe(true);
      expect(completedInfo.text()).toEqual('3/10 steps completed');
    });

    it('does not render "3/10 steps completed" below the second tour item', () => {
      const completedInfo = tourItems.at(1).find('.text-secondary');

      expect(completedInfo.exists()).toBe(false);
    });
  });
});
