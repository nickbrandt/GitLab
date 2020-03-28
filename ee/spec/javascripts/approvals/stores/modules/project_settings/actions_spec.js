import MockAdapter from 'axios-mock-adapter';
import testAction from 'spec/helpers/vuex_action_helper';
import * as types from 'ee/approvals/stores/modules/base/mutation_types';
import actionsModule, * as actions from 'ee/approvals/stores/modules/project_settings/actions';
import { mapApprovalRuleRequest, mapApprovalSettingsResponse } from 'ee/approvals/mappers';
import axios from '~/lib/utils/axios_utils';

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
const TEST_SETTINGS_PATH = 'projects/9/approval_settings';
const TEST_RULES_PATH = 'projects/9/approval_settings/rules';

describe('EE approvals project settings module actions', () => {
  let state;
  let flashSpy;
  let mock;

  beforeEach(() => {
    state = {
      settings: {
        projectId: TEST_PROJECT_ID,
        settingsPath: TEST_SETTINGS_PATH,
        rulesPath: TEST_RULES_PATH,
      },
    };
    flashSpy = spyOnDependency(actionsModule, 'createFlash');
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
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
      const settings = { rules: [{ id: 1 }] };

      testAction(
        actions.receiveRulesSuccess,
        settings,
        {},
        [
          { type: types.SET_APPROVAL_SETTINGS, payload: settings },
          { type: types.SET_LOADING, payload: false },
        ],
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
    it('dispatches request/receive', done => {
      const data = { rules: [TEST_RULE_RESPONSE] };
      mock.onGet(TEST_SETTINGS_PATH).replyOnce(200, data);

      testAction(
        actions.fetchRules,
        null,
        state,
        [],
        [
          { type: 'requestRules' },
          { type: 'receiveRulesSuccess', payload: mapApprovalSettingsResponse(data) },
        ],
        () => {
          expect(mock.history.get.map(x => x.url)).toEqual([TEST_SETTINGS_PATH]);

          done();
        },
      );
    });

    it('dispatches request/receive on error', done => {
      mock.onGet(TEST_SETTINGS_PATH).replyOnce(500);

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
      mock.onPost(TEST_RULES_PATH).replyOnce(200);

      testAction(
        actions.postRule,
        TEST_RULE_REQUEST,
        state,
        [],
        [{ type: 'postRuleSuccess' }],
        () => {
          expect(mock.history.post).toEqual([
            jasmine.objectContaining({
              url: TEST_RULES_PATH,
              data: JSON.stringify(mapApprovalRuleRequest(TEST_RULE_REQUEST)),
            }),
          ]);

          done();
        },
      );
    });

    it('dispatches error on error', done => {
      mock.onPost(TEST_RULES_PATH).replyOnce(500);

      testAction(actions.postRule, TEST_RULE_REQUEST, state, [], [{ type: 'postRuleError' }], done);
    });
  });

  describe('putRule', () => {
    it('dispatches success on success', done => {
      mock.onPut(`${TEST_RULES_PATH}/${TEST_RULE_ID}`).replyOnce(200);

      testAction(
        actions.putRule,
        { id: TEST_RULE_ID, ...TEST_RULE_REQUEST },
        state,
        [],
        [{ type: 'postRuleSuccess' }],
        () => {
          expect(mock.history.put).toEqual([
            jasmine.objectContaining({
              url: `${TEST_RULES_PATH}/${TEST_RULE_ID}`,
              data: JSON.stringify(mapApprovalRuleRequest(TEST_RULE_REQUEST)),
            }),
          ]);

          done();
        },
      );
    });

    it('dispatches error on error', done => {
      mock.onPut(`${TEST_RULES_PATH}/${TEST_RULE_ID}`).replyOnce(500);

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
      mock.onDelete(`${TEST_RULES_PATH}/${TEST_RULE_ID}`).replyOnce(200);

      testAction(
        actions.deleteRule,
        TEST_RULE_ID,
        state,
        [],
        [{ type: 'deleteRuleSuccess' }],
        () => {
          expect(mock.history.delete).toEqual([
            jasmine.objectContaining({
              url: `${TEST_RULES_PATH}/${TEST_RULE_ID}`,
            }),
          ]);

          done();
        },
      );
    });

    it('dispatches error on error', done => {
      mock.onDelete(`${TEST_RULES_PATH}/${TEST_RULE_ID}`).replyOnce(500);

      testAction(actions.deleteRule, TEST_RULE_ID, state, [], [{ type: 'deleteRuleError' }], done);
    });
  });
});
