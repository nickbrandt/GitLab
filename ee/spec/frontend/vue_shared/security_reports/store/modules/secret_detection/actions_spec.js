import testAction from 'helpers/vuex_action_helper';
import createState from 'ee/vue_shared/security_reports/store/modules/secret_detection/state';
import * as types from 'ee/vue_shared/security_reports/store/modules/secret_detection/mutation_types';
import * as actions from 'ee/vue_shared/security_reports/store/modules/secret_detection/actions';

const issue = {};
let state;

// See also the corresponding CE specs in
// spec/frontend/vue_shared/security_reports/store/modules/secret_detection/actions_spec.js
describe('EE secret detection report actions', () => {
  beforeEach(() => {
    state = createState();
  });

  describe('updateSecretScanningIssue', () => {
    it(`should commit ${types.UPDATE_SECRET_SCANNING_ISSUE} with the correct response`, done => {
      testAction(
        actions.updateSecretScanningIssue,
        issue,
        state,
        [
          {
            type: types.UPDATE_SECRET_SCANNING_ISSUE,
            payload: issue,
          },
        ],
        [],
        done,
      );
    });
  });
});
