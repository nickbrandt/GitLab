import mutations from 'ee/subscriptions/new/store/mutations';
import * as types from 'ee/subscriptions/new/store/mutation_types';

const state = () => ({
  currentStep: 'firstStep',
});

let stateCopy;

beforeEach(() => {
  stateCopy = state();
});

describe('ACTIVATE_STEP', () => {
  it('should set the currentStep to the given step', () => {
    mutations[types.ACTIVATE_STEP](stateCopy, 'secondStep');

    expect(stateCopy.currentStep).toEqual('secondStep');
  });
});
