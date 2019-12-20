import * as getters from 'ee/subscriptions/new/store/getters';
import * as constants from 'ee/subscriptions/new/constants';

constants.STEPS = ['firstStep', 'secondStep'];

const state = {
  currentStep: 'secondStep',
};

describe('Subscriptions Getters', () => {
  describe('currentStep', () => {
    it('returns the states currentStep', () => {
      expect(getters.currentStep(state)).toEqual('secondStep');
    });
  });

  describe('stepIndex', () => {
    it('returns a function', () => {
      expect(getters.stepIndex()).toBeInstanceOf(Function);
    });

    it('returns a function that returns the index of the given step', () => {
      expect(getters.stepIndex()('secondStep')).toEqual(1);
    });
  });

  describe('activeStepIndex', () => {
    it('returns a function', () => {
      expect(getters.activeStepIndex(state, getters)).toBeInstanceOf(Function);
    });

    it('calls the stepIndex function with the current step name', () => {
      const stepIndexSpy = jest.spyOn(getters, 'stepIndex');
      getters.activeStepIndex(state, getters);

      expect(stepIndexSpy).toHaveBeenCalledWith('secondStep');
    });
  });
});
