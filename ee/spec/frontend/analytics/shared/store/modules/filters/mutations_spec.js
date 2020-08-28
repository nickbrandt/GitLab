import mutations from 'ee/analytics/shared/store/modules/filters/mutations';
import * as types from 'ee/analytics/shared/store/modules/filters/mutation_types';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { filterMilestones, filterUsers, filterLabels } from './mock_data';

let state = null;

const milestones = filterMilestones.map(convertObjectPropsToCamelCase);
const users = filterUsers.map(convertObjectPropsToCamelCase);
const labels = filterLabels.map(convertObjectPropsToCamelCase);

describe('Filters mutations', () => {
  const errorCode = 500;
  beforeEach(() => {
    state = {
      authors: { selected: null },
      milestones: { selected: null },
      assignees: { selected: [] },
      labels: { selected: [] },
    };
  });

  afterEach(() => {
    state = null;
  });

  it.each`
    mutation                         | stateKey                | value
    ${types.SET_MILESTONES_ENDPOINT} | ${'milestonesEndpoint'} | ${'new-milestone-endpoint'}
    ${types.SET_LABELS_ENDPOINT}     | ${'labelsEndpoint'}     | ${'new-label-endpoint'}
  `('$mutation will set $stateKey=$value', ({ mutation, stateKey, value }) => {
    mutations[mutation](state, value);

    expect(state[stateKey]).toEqual(value);
  });

  it.each`
    mutation                      | stateKey        | value
    ${types.SET_SELECTED_FILTERS} | ${'authors'}    | ${null}
    ${types.SET_SELECTED_FILTERS} | ${'milestones'} | ${null}
    ${types.SET_SELECTED_FILTERS} | ${'assignees'}  | ${[]}
    ${types.SET_SELECTED_FILTERS} | ${'labels'}     | ${[]}
  `('$mutation will set $stateKey with a given value', ({ mutation, stateKey, value }) => {
    mutations[mutation](state, { [stateKey]: { selected: value } });

    expect(state[stateKey].selected).toEqual(value);
  });

  it.each`
    mutation                            | rootKey         | stateKey       | value
    ${types.REQUEST_MILESTONES}         | ${'milestones'} | ${'isLoading'} | ${true}
    ${types.RECEIVE_MILESTONES_SUCCESS} | ${'milestones'} | ${'isLoading'} | ${false}
    ${types.RECEIVE_MILESTONES_SUCCESS} | ${'milestones'} | ${'data'}      | ${milestones}
    ${types.RECEIVE_MILESTONES_SUCCESS} | ${'milestones'} | ${'errorCode'} | ${null}
    ${types.RECEIVE_MILESTONES_ERROR}   | ${'milestones'} | ${'isLoading'} | ${false}
    ${types.RECEIVE_MILESTONES_ERROR}   | ${'milestones'} | ${'data'}      | ${[]}
    ${types.RECEIVE_MILESTONES_ERROR}   | ${'milestones'} | ${'errorCode'} | ${errorCode}
    ${types.REQUEST_AUTHORS}            | ${'authors'}    | ${'isLoading'} | ${true}
    ${types.RECEIVE_AUTHORS_SUCCESS}    | ${'authors'}    | ${'isLoading'} | ${false}
    ${types.RECEIVE_AUTHORS_SUCCESS}    | ${'authors'}    | ${'data'}      | ${users}
    ${types.RECEIVE_AUTHORS_SUCCESS}    | ${'authors'}    | ${'errorCode'} | ${null}
    ${types.RECEIVE_AUTHORS_ERROR}      | ${'authors'}    | ${'isLoading'} | ${false}
    ${types.RECEIVE_AUTHORS_ERROR}      | ${'authors'}    | ${'data'}      | ${[]}
    ${types.RECEIVE_AUTHORS_ERROR}      | ${'authors'}    | ${'errorCode'} | ${errorCode}
    ${types.REQUEST_LABELS}             | ${'labels'}     | ${'isLoading'} | ${true}
    ${types.RECEIVE_LABELS_SUCCESS}     | ${'labels'}     | ${'isLoading'} | ${false}
    ${types.RECEIVE_LABELS_SUCCESS}     | ${'labels'}     | ${'data'}      | ${labels}
    ${types.RECEIVE_LABELS_SUCCESS}     | ${'labels'}     | ${'errorCode'} | ${null}
    ${types.RECEIVE_LABELS_ERROR}       | ${'labels'}     | ${'isLoading'} | ${false}
    ${types.RECEIVE_LABELS_ERROR}       | ${'labels'}     | ${'data'}      | ${[]}
    ${types.RECEIVE_LABELS_ERROR}       | ${'labels'}     | ${'errorCode'} | ${errorCode}
    ${types.REQUEST_ASSIGNEES}          | ${'assignees'}  | ${'isLoading'} | ${true}
    ${types.RECEIVE_ASSIGNEES_SUCCESS}  | ${'assignees'}  | ${'isLoading'} | ${false}
    ${types.RECEIVE_ASSIGNEES_SUCCESS}  | ${'assignees'}  | ${'data'}      | ${users}
    ${types.RECEIVE_ASSIGNEES_SUCCESS}  | ${'assignees'}  | ${'errorCode'} | ${null}
    ${types.RECEIVE_ASSIGNEES_ERROR}    | ${'assignees'}  | ${'isLoading'} | ${false}
    ${types.RECEIVE_ASSIGNEES_ERROR}    | ${'assignees'}  | ${'data'}      | ${[]}
    ${types.RECEIVE_ASSIGNEES_ERROR}    | ${'assignees'}  | ${'errorCode'} | ${errorCode}
  `('$mutation will set $stateKey with a given value', ({ mutation, rootKey, stateKey, value }) => {
    mutations[mutation](state, value);

    expect(state[rootKey][stateKey]).toEqual(value);
  });
});
