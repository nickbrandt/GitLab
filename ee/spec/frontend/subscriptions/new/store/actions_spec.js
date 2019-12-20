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
        [{ type: 'ACTIVATE_STEP', payload: 'secondStep' }],
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
        { activeStepIndex: 0 },
        [{ type: 'ACTIVATE_STEP', payload: 'secondStep' }],
        [],
        done,
      );
    });

    it('does not change the currentStep if the current step is the last step', done => {
      testAction(actions.activateNextStep, {}, { activeStepIndex: 1 }, [], [], done);
    });
  });
});
