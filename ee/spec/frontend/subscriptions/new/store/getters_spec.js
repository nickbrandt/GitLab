import * as getters from 'ee/subscriptions/new/store/getters';
import * as constants from 'ee/subscriptions/new/constants';

constants.STEPS = ['firstStep', 'secondStep'];

const state = {
  currentStep: 'secondStep',
  isSetupForCompany: true,
  availablePlans: [
    {
      value: 'firstPlan',
      text: 'first plan',
    },
  ],
  selectedPlan: 'firstPlan',
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

  describe('currentStepIndex', () => {
    it('returns a function', () => {
      expect(getters.currentStepIndex(state, getters)).toBeInstanceOf(Function);
    });

    it('calls the stepIndex function with the current step name', () => {
      const stepIndexSpy = jest.spyOn(getters, 'stepIndex');
      getters.currentStepIndex(state, getters);

      expect(stepIndexSpy).toHaveBeenCalledWith('secondStep');
    });
  });

  describe('selectedPlanText', () => {
    it('returns the text for selectedPlan', () => {
      expect(
        getters.selectedPlanText(state, { selectedPlanDetails: { text: 'selected plan' } }),
      ).toEqual('selected plan');
    });
  });

  describe('selectedPlanDetails', () => {
    it('returns the details for the selected plan', () => {
      expect(getters.selectedPlanDetails(state)).toEqual({
        value: 'firstPlan',
        text: 'first plan',
      });
    });
  });
});
