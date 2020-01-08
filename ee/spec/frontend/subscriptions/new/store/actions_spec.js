import testAction from 'helpers/vuex_action_helper';
import * as actions from 'ee/subscriptions/new/store/actions';
import * as constants from 'ee/subscriptions/new/constants';

constants.STEPS = ['firstStep', 'secondStep'];

describe('Subscriptions Actions', () => {
  describe('activateStep', () => {
    it('set the currentStep to the provided value', done => {
      testAction(
        actions.activateStep,
        'secondStep',
        {},
        [{ type: 'UPDATE_CURRENT_STEP', payload: 'secondStep' }],
        [],
        done,
      );
    });

    it('does not change the currentStep if provided value is not available', done => {
      testAction(actions.activateStep, 'thirdStep', {}, [], [], done);
    });
  });

  describe('activateNextStep', () => {
    it('set the currentStep to the next step in the available steps', done => {
      testAction(
        actions.activateNextStep,
        {},
        { currentStepIndex: 0 },
        [{ type: 'UPDATE_CURRENT_STEP', payload: 'secondStep' }],
        [],
        done,
      );
    });

    it('does not change the currentStep if the current step is the last step', done => {
      testAction(actions.activateNextStep, {}, { currentStepIndex: 1 }, [], [], done);
    });
  });

  describe('updateSelectedPlan', () => {
    it('updates the selected plan', done => {
      testAction(
        actions.updateSelectedPlan,
        'planId',
        {},
        [{ type: 'UPDATE_SELECTED_PLAN', payload: 'planId' }],
        [],
        done,
      );
    });
  });

  describe('toggleIsSetupForCompany', () => {
    it('toggles the isSetupForCompany value', done => {
      testAction(
        actions.toggleIsSetupForCompany,
        {},
        { isSetupForCompany: true },
        [{ type: 'UPDATE_IS_SETUP_FOR_COMPANY', payload: false }],
        [],
        done,
      );
    });
  });

  describe('updateNumberOfUsers', () => {
    it('updates numberOfUsers to 0 when no value is provided', done => {
      testAction(
        actions.updateNumberOfUsers,
        null,
        {},
        [{ type: 'UPDATE_NUMBER_OF_USERS', payload: 0 }],
        [],
        done,
      );
    });

    it('updates numberOfUsers when a value is provided', done => {
      testAction(
        actions.updateNumberOfUsers,
        2,
        {},
        [{ type: 'UPDATE_NUMBER_OF_USERS', payload: 2 }],
        [],
        done,
      );
    });
  });

  describe('updateOrganizationName', () => {
    it('updates organizationName to the provided value', done => {
      testAction(
        actions.updateOrganizationName,
        'name',
        {},
        [{ type: 'UPDATE_ORGANIZATION_NAME', payload: 'name' }],
        [],
        done,
      );
    });
  });
});
