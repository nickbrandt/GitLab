import testAction from 'spec/helpers/vuex_action_helper';
import * as types from 'ee/approvals/stores/mutation_types';
import actionsModule, * as actions from 'ee/approvals/stores/actions';
import service from 'ee/approvals/services/approvals_service_stub';

describe('EE approvals store actions', () => {
  let flashSpy;

  beforeEach(() => {
    flashSpy = spyOnDependency(actionsModule, 'createFlash');
    spyOn(service, 'getProjectApprovalRules');
  });

  describe('setSettings', () => {
    it('sets the settings', done => {
      const settings = { projectId: 7 };

      testAction(
        actions.setSettings,
        settings,
        {},
        [{ type: types.SET_SETTINGS, payload: settings }],
        [],
        done,
      );
    });
  });

  describe('requestRules', () => {
    it('sets loading', done => {
      testAction(
        actions.requestRules,
        null,
        {},
        [{ type: types.SET_LOADING, payload: true }],
        [],
        done,
      );
    });
  });

  describe('receiveRulesSuccess', () => {
    it('sets rules', done => {
      const rules = [{ id: 1 }];

      testAction(
        actions.receiveRulesSuccess,
        { rules },
        {},
        [{ type: types.SET_RULES, payload: rules }, { type: types.SET_LOADING, payload: false }],
        [],
        done,
      );
    });
  });

  describe('receiveRulesError', () => {
    it('creates a flash', () => {
      expect(flashSpy).not.toHaveBeenCalled();

      actions.receiveRulesError();

      expect(flashSpy).toHaveBeenCalledTimes(1);
      expect(flashSpy).toHaveBeenCalledWith(jasmine.stringMatching('error occurred'));
    });
  });

  describe('fetchRules', () => {
    it('does nothing if loading', done => {
      testAction(actions.fetchRules, null, { isLoading: true }, [], [], done);
    });

    it('dispatches request/receive', done => {
      const response = {
        data: { rules: [] },
      };
      service.getProjectApprovalRules.and.returnValue(Promise.resolve(response));

      testAction(
        actions.fetchRules,
        null,
        {},
        [],
        [{ type: 'requestRules' }, { type: 'receiveRulesSuccess', payload: response.data }],
        done,
      );
    });

    it('dispatches request/receive on error', done => {
      service.getProjectApprovalRules.and.returnValue(Promise.reject());

      testAction(
        actions.fetchRules,
        null,
        {},
        [],
        [{ type: 'requestRules' }, { type: 'receiveRulesError' }],
        done,
      );
    });
  });
});
