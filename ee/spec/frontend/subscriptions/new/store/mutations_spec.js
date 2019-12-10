import mutations from 'ee/subscriptions/new/store/mutations';
import * as types from 'ee/subscriptions/new/store/mutation_types';

const state = () => ({
  currentStep: 'firstStep',
  selectedPlan: 'firstPlan',
  isSetupForCompany: true,
  numberOfUsers: 1,
  organizationName: 'name',
});

let stateCopy;

beforeEach(() => {
  stateCopy = state();
});

describe('UPDATE_CURRENT_STEP', () => {
  it('should set the currentStep to the given step', () => {
    mutations[types.UPDATE_CURRENT_STEP](stateCopy, 'secondStep');

    expect(stateCopy.currentStep).toEqual('secondStep');
  });
});

describe('UPDATE_SELECTED_PLAN', () => {
  it('should set the selectedPlan to the given plan', () => {
    mutations[types.UPDATE_SELECTED_PLAN](stateCopy, 'secondPlan');

    expect(stateCopy.selectedPlan).toEqual('secondPlan');
  });
});

describe('UPDATE_IS_SETUP_FOR_COMPANY', () => {
  it('should set the isSetupForCompany to the given boolean', () => {
    mutations[types.UPDATE_IS_SETUP_FOR_COMPANY](stateCopy, false);

    expect(stateCopy.isSetupForCompany).toEqual(false);
  });
});

describe('UPDATE_NUMBER_OF_USERS', () => {
  it('should set the numberOfUsers to the given number', () => {
    mutations[types.UPDATE_NUMBER_OF_USERS](stateCopy, 2);

    expect(stateCopy.numberOfUsers).toEqual(2);
  });
});

describe('UPDATE_ORGANIZATION_NAME', () => {
  it('should set the organizationName to the given name', () => {
    mutations[types.UPDATE_ORGANIZATION_NAME](stateCopy, 'new name');

    expect(stateCopy.organizationName).toEqual('new name');
  });
});
