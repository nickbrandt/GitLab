import Api from 'ee/api';
import testAction from 'spec/helpers/vuex_action_helper';
import * as types from 'ee/approvals/stores/mutation_types';
import actionsModule, * as actions from 'ee/approvals/stores/actions';
import { mapApprovalRuleRequest, mapApprovalRulesResponse } from 'ee/approvals/mappers';

const TEST_PROJECT_ID = 9;
const TEST_RULE_ID = 7;
const TEST_RULE_REQUEST = {
  name: 'Lorem',
  approvalsRequired: 1,
  groups: [7],
  users: [8, 9],
};
const TEST_RULE_RESPONSE = {
  id: 7,
  name: 'Ipsum',
  approvals_required: 2,
  approvers: [{ id: 7 }, { id: 8 }, { id: 9 }],
  groups: [{ id: 4 }],
  users: [{ id: 7 }, { id: 8 }],
};

describe('EE approvals store actions', () => {
  let state;
  let flashSpy;

  beforeEach(() => {
    state = {
      settings: { projectId: TEST_PROJECT_ID },
    };
    flashSpy = spyOnDependency(actionsModule, 'createFlash');
    spyOn(Api, 'getProjectApprovalRules');
    spyOn(Api, 'postProjectApprovalRule');
    spyOn(Api, 'putProjectApprovalRule');
    spyOn(Api, 'deleteProjectApprovalRule');
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
        data: { rules: [TEST_RULE_RESPONSE] },
      };
      Api.getProjectApprovalRules.and.returnValue(Promise.resolve(response));

      testAction(
        actions.fetchRules,
        null,
        state,
        [],
        [
          { type: 'requestRules' },
          { type: 'receiveRulesSuccess', payload: mapApprovalRulesResponse(response.data) },
        ],
        () => {
          expect(Api.getProjectApprovalRules).toHaveBeenCalledWith(TEST_PROJECT_ID);

          done();
        },
      );
    });

    it('dispatches request/receive on error', done => {
      Api.getProjectApprovalRules.and.returnValue(Promise.reject());

      testAction(
        actions.fetchRules,
        null,
        state,
        [],
        [{ type: 'requestRules' }, { type: 'receiveRulesError' }],
        done,
      );
    });
  });

  describe('postRuleSuccess', () => {
    it('closes modal and fetches', done => {
      testAction(
        actions.postRuleSuccess,
        null,
        {},
        [],
        [{ type: 'createModal/close' }, { type: 'fetchRules' }],
        done,
      );
    });
  });

  describe('postRuleError', () => {
    it('creates a flash', () => {
      expect(flashSpy).not.toHaveBeenCalled();

      actions.postRuleError();

      expect(flashSpy.calls.allArgs()).toEqual([[jasmine.stringMatching('error occurred')]]);
    });
  });

  describe('postRule', () => {
    it('dispatches success on success', done => {
      Api.postProjectApprovalRule.and.returnValue(Promise.resolve());

      testAction(
        actions.postRule,
        TEST_RULE_REQUEST,
        state,
        [],
        [{ type: 'postRuleSuccess' }],
        () => {
          expect(Api.postProjectApprovalRule).toHaveBeenCalledWith(
            TEST_PROJECT_ID,
            mapApprovalRuleRequest(TEST_RULE_REQUEST),
          );
          done();
        },
      );
    });

    it('dispatches error on error', done => {
      Api.postProjectApprovalRule.and.returnValue(Promise.reject());

      testAction(
        actions.postRule,
        TEST_RULE_REQUEST,
        state,
        [],
        [{ type: 'postRuleError' }],
        () => {
          expect(Api.postProjectApprovalRule).toHaveBeenCalledWith(
            TEST_PROJECT_ID,
            mapApprovalRuleRequest(TEST_RULE_REQUEST),
          );

          done();
        },
      );
    });
  });

  describe('putRule', () => {
    it('dispatches success on success', done => {
      Api.putProjectApprovalRule.and.returnValue(Promise.resolve());

      testAction(
        actions.putRule,
        { id: TEST_RULE_ID, ...TEST_RULE_REQUEST },
        state,
        [],
        [{ type: 'postRuleSuccess' }],
        () => {
          expect(Api.putProjectApprovalRule).toHaveBeenCalledWith(
            TEST_PROJECT_ID,
            TEST_RULE_ID,
            mapApprovalRuleRequest(TEST_RULE_REQUEST),
          );
          done();
        },
      );
    });

    it('dispatches error on error', done => {
      Api.putProjectApprovalRule.and.returnValue(Promise.reject());

      testAction(
        actions.putRule,
        { id: TEST_RULE_ID, ...TEST_RULE_REQUEST },
        state,
        [],
        [{ type: 'postRuleError' }],
        done,
      );
    });
  });

  describe('deleteRuleSuccess', () => {
    it('closes modal and fetches', done => {
      testAction(
        actions.deleteRuleSuccess,
        null,
        {},
        [],
        [{ type: 'deleteModal/close' }, { type: 'fetchRules' }],
        done,
      );
    });
  });

  describe('deleteRuleError', () => {
    it('creates a flash', () => {
      expect(flashSpy).not.toHaveBeenCalled();

      actions.deleteRuleError();

      expect(flashSpy.calls.allArgs()).toEqual([[jasmine.stringMatching('error occurred')]]);
    });
  });

  describe('deleteRule', () => {
    it('dispatches success on success', done => {
      Api.deleteProjectApprovalRule.and.returnValue(Promise.resolve());

      testAction(
        actions.deleteRule,
        TEST_RULE_ID,
        state,
        [],
        [{ type: 'deleteRuleSuccess' }],
        () => {
          expect(Api.deleteProjectApprovalRule).toHaveBeenCalledWith(TEST_PROJECT_ID, TEST_RULE_ID);

          done();
        },
      );
    });

    it('dispatches error on error', done => {
      Api.deleteProjectApprovalRule.and.returnValue(Promise.reject());

      testAction(actions.deleteRule, TEST_RULE_ID, state, [], [{ type: 'deleteRuleError' }], done);
    });
  });
});
