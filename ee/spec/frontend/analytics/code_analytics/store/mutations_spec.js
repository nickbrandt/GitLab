import mutations from 'ee/analytics/code_analytics/store/mutations';
import * as types from 'ee/analytics/code_analytics/store/mutation_types';
import { group, project } from '../mock_data';

describe('Cycle analytics mutations', () => {
  let state;

  beforeEach(() => {
    state = {};
  });

  afterEach(() => {
    state = {};
  });

  it.each`
    mutation                            | payload       | expectedState
    ${types.SET_SELECTED_GROUP}         | ${group.name} | ${{ selectedGroup: group.name, selectedProject: null }}
    ${types.SET_SELECTED_PROJECT}       | ${project}    | ${{ selectedProject: project }}
    ${types.SET_SELECTED_FILE_QUANTITY} | ${250}        | ${{ selectedFileQuantity: 250 }}
  `(
    '$mutation with payload $payload will update state with $expectedState',
    ({ mutation, payload, expectedState }) => {
      mutations[mutation](state, payload);

      expect(state).toMatchObject(expectedState);
    },
  );
});
