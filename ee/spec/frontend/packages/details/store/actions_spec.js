import Api from '~/api';
import * as actions from 'ee/packages/details/store/actions';
import * as types from 'ee/packages/details/store/mutation_types';
import testAction from 'helpers/vuex_action_helper';
import createFlash from '~/flash';
import { mockPipelineInfo, npmPackage } from '../../mock_data';

jest.mock('~/api.js');
jest.mock('~/flash.js');

describe('Actions PackageDetails Store', () => {
  let state;

  const defaultState = {
    packageEntity: npmPackage,
  };

  beforeEach(() => {
    state = defaultState;
  });

  describe('fetch pipeline info', () => {
    it('sets pipelineError to null and pipelineInfo to the returned data', done => {
      Api.pipelineSingle = jest.fn().mockResolvedValue({ data: mockPipelineInfo });

      testAction(
        actions.fetchPipelineInfo,
        null,
        state,
        [
          { type: types.SET_PIPELINE_ERROR, payload: null },
          { type: types.SET_PIPELINE_INFO, payload: mockPipelineInfo },
        ],
        [{ type: 'toggleLoading' }, { type: 'toggleLoading' }],
        done,
      );
    });

    it('should create flash on API error and set pipelineError', done => {
      Api.pipelineSingle = jest.fn().mockRejectedValue();

      testAction(
        actions.fetchPipelineInfo,
        null,
        state,
        [
          {
            type: types.SET_PIPELINE_ERROR,
            payload: 'Unable to fetch pipeline information',
          },
        ],
        [{ type: 'toggleLoading' }, { type: 'toggleLoading' }],
        () => {
          expect(createFlash).toHaveBeenCalled();
          done();
        },
      );
    });
  });

  describe('toggles loading', () => {
    it('sets isLoading to true', done => {
      testAction(actions.toggleLoading, {}, state, [{ type: types.TOGGLE_LOADING }], [], done);
    });

    it('toggles isLoading to false', done => {
      testAction(
        actions.toggleLoading,
        {},
        { ...state, isLoading: true },
        [{ type: types.TOGGLE_LOADING }],
        [],
        done,
      );
    });
  });
});
