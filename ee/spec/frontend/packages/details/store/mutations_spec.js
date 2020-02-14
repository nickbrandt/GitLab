import * as types from 'ee/packages/details/store/mutation_types';
import mutations from 'ee/packages/details/store/mutations';
import { mockPipelineInfo as pipelineInfo } from '../../mock_data';

describe('Mutations PackageDetails Store', () => {
  let mockState;

  const defaultState = {
    packageEntity: null,
    packageFiles: [],
    pipelineInfo: {},
    pipelineError: null,
    isLoading: false,
  };

  beforeEach(() => {
    mockState = defaultState;
  });

  describe('set package info', () => {
    it('should set packageInfo', () => {
      const expectedState = { ...mockState, pipelineInfo };
      mutations[types.SET_PIPELINE_INFO](mockState, pipelineInfo);

      expect(mockState.pipelineInfo).toEqual(expectedState.pipelineInfo);
    });
  });

  describe('set pipeline error', () => {
    it('should set pipelineError', () => {
      const pipelineError = 'a-pipeline-error-message';
      const expectedState = { ...mockState, pipelineError };
      mutations[types.SET_PIPELINE_ERROR](mockState, pipelineError);

      expect(mockState.pipelineError).toEqual(expectedState.pipelineError);
    });
  });

  describe('toggle loading', () => {
    it('should set to true', () => {
      const expectedState = Object.assign({}, mockState, { isLoading: true });
      mutations[types.TOGGLE_LOADING](mockState);

      expect(mockState.isLoading).toEqual(expectedState.isLoading);
    });

    it('should toggle back to false', () => {
      const expectedState = Object.assign({}, mockState, { isLoading: false });
      mockState.isLoading = true;

      mutations[types.TOGGLE_LOADING](mockState);

      expect(mockState.isLoading).toEqual(expectedState.isLoading);
    });
  });
});
