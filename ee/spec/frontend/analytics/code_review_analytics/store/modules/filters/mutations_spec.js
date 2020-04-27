import * as types from 'ee/analytics/code_review_analytics/store/modules/filters/mutation_types';
import mutations from 'ee/analytics/code_review_analytics/store/modules/filters/mutations';
import getInitialState from 'ee/analytics/code_review_analytics/store/modules/filters/state';
import { mockMilestones, mockLabels } from '../../../mock_data';

describe('Code review analytics filters mutations', () => {
  let state;

  const milestoneTitle = 'my milestone';
  const labelName = ['first label', 'second label'];

  beforeEach(() => {
    state = getInitialState();
  });

  describe(types.SET_MILESTONES_ENDPOINT, () => {
    it('sets the milestone path', () => {
      mutations[types.SET_MILESTONES_ENDPOINT](state, 'milestone_path');

      expect(state.milestonesEndpoint).toEqual('milestone_path');
    });
  });

  describe(types.SET_LABELS_ENDPOINT, () => {
    it('sets the labels path', () => {
      mutations[types.SET_LABELS_ENDPOINT](state, 'labels_path');

      expect(state.labelsEndpoint).toEqual('labels_path');
    });
  });

  describe(types.REQUEST_MILESTONES, () => {
    it('sets isLoading to true', () => {
      mutations[types.REQUEST_MILESTONES](state);

      expect(state.milestones.isLoading).toBe(true);
    });
  });

  describe(types.RECEIVE_MILESTONES_SUCCESS, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_MILESTONES_SUCCESS](state, mockMilestones);
    });

    it.each`
      stateProp      | value
      ${'isLoading'} | ${false}
      ${'errorCode'} | ${null}
      ${'data'}      | ${mockMilestones}
    `('sets $stateProp to $value', ({ stateProp, value }) => {
      expect(state.milestones[stateProp]).toEqual(value);
    });
  });

  describe(types.RECEIVE_MILESTONES_ERROR, () => {
    const errorCode = 500;
    beforeEach(() => {
      mutations[types.RECEIVE_MILESTONES_ERROR](state, errorCode);
    });

    it.each`
      stateProp      | value
      ${'isLoading'} | ${false}
      ${'errorCode'} | ${errorCode}
      ${'data'}      | ${[]}
    `('sets $stateProp to $value', ({ stateProp, value }) => {
      expect(state.milestones[stateProp]).toEqual(value);
    });
  });

  describe(types.REQUEST_LABELS, () => {
    it('sets isLoading to true', () => {
      mutations[types.REQUEST_LABELS](state);

      expect(state.labels.isLoading).toBe(true);
    });
  });

  describe(types.RECEIVE_LABELS_SUCCESS, () => {
    beforeEach(() => {
      mutations[types.RECEIVE_LABELS_SUCCESS](state, mockLabels);
    });

    it.each`
      stateProp      | value
      ${'isLoading'} | ${false}
      ${'errorCode'} | ${null}
      ${'data'}      | ${mockLabels}
    `('sets $stateProp to $value', ({ stateProp, value }) => {
      expect(state.labels[stateProp]).toEqual(value);
    });
  });

  describe(types.RECEIVE_LABELS_ERROR, () => {
    const errorCode = 500;
    beforeEach(() => {
      mutations[types.RECEIVE_LABELS_ERROR](state, errorCode);
    });

    it.each`
      stateProp      | value
      ${'isLoading'} | ${false}
      ${'errorCode'} | ${errorCode}
      ${'data'}      | ${[]}
    `('sets $stateProp to $value', ({ stateProp, value }) => {
      expect(state.labels[stateProp]).toEqual(value);
    });
  });

  describe(types.SET_FILTERS, () => {
    it('updates selected milestone and labels', () => {
      mutations[types.SET_FILTERS](state, {
        selectedMilestone: milestoneTitle,
        selectedLabels: labelName,
      });

      expect(state.milestones.selected).toBe(milestoneTitle);
      expect(state.labels.selected).toBe(labelName);
    });
  });
});
