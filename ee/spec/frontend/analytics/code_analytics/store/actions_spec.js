import testAction from 'helpers/vuex_action_helper';
import * as actions from 'ee/analytics/code_analytics/store/actions';
import * as types from 'ee/analytics/code_analytics/store/mutation_types';
import { group, project } from '../mock_data';

describe('Cycle analytics actions', () => {
  let state;

  beforeEach(() => {
    state = {};
  });

  it.each`
    action                       | type                                | stateKey                  | payload
    ${'setSelectedGroup'}        | ${types.SET_SELECTED_GROUP}         | ${'selectedGroup'}        | ${group.name}
    ${'setSelectedProject'}      | ${types.SET_SELECTED_PROJECT}       | ${'selectedProject'}      | ${project}
    ${'setSelectedFileQuantity'} | ${types.SET_SELECTED_FILE_QUANTITY} | ${'selectedFileQuantity'} | ${250}
  `('$action should set $stateKey with $payload and type $type', ({ action, type, payload }) => {
    testAction(
      actions[action],
      payload,
      state,
      [
        {
          type,
          payload,
        },
      ],
      [],
    );
  });
});
