import mutations from 'ee/analytics/cycle_analytics/store/modules/filters/mutations';
import * as types from 'ee/analytics/cycle_analytics/store/modules/filters/mutation_types';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { filterMilestones, filterUsers, filterLabels } from '../../../mock_data';

let state = null;

const milestones = filterMilestones.map(convertObjectPropsToCamelCase);
const users = filterUsers.map(convertObjectPropsToCamelCase);
const labels = filterLabels.map(convertObjectPropsToCamelCase);

describe('Filters mutations', () => {
  beforeEach(() => {
    state = { initialTokens: {}, milestones: {}, authors: {}, labels: {}, assignees: {} };
  });

  afterEach(() => {
    state = null;
  });

  it.each`
    mutation                     | stateKey            | value
    ${types.SET_MILESTONES_PATH} | ${'milestonesPath'} | ${'new-milestone-path'}
    ${types.SET_LABELS_PATH}     | ${'labelsPath'}     | ${'new-label-path'}
  `('$mutation will set $stateKey=$value', ({ mutation, stateKey, value }) => {
    mutations[mutation](state, value);

    expect(state[stateKey]).toEqual(value);
  });
});
