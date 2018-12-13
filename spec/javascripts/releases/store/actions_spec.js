import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import {
  setEndpoint,
  requestReleases,
  fetchReleases,
  receiveReleasesSuccess,
  receiveReleasesError,
} from '~/releases/store/actions';
import state from '~/releases/store/state';
import * as types from '~/releases/store/mutation_types';
import testAction from 'spec/helpers/vuex_action_helper';
import { releases } from '../mock_data';

describe('Releases State actions', () => {
  let mockedState;

  beforeEach(() => {
    mockedState = state();
  });

  describe('setEndpoint', () => {
    it('should commit SET_ENDPOINT mutation', done => {
      testAction(
        setEndpoint,
        'endpoint.json',
        mockedState,
        [{ type: types.SET_ENDPOINT, payload: 'endpoint.json' }],
        [],
        done,
      );
    });
  });

  describe('requestReleases', () => {
    it('should commit REQUEST_RELEASES mutation', done => {
      testAction(requestReleases, null, mockedState, [{ type: types.REQUEST_RELEASES }], [], done);
    });
  });

  describe('fetchReleases', () => {
    let mock;

    beforeEach(() => {
      mockedState.endpoint = 'endpoint.json';
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('success', () => {
      it('dispatches requestReleases and receiveReleasesSuccess ', done => {
        mock.onGet('endpoint.json').replyOnce(200, releases);

        testAction(
          fetchReleases,
          releases,
          mockedState,
          [],
          [
            {
              type: 'requestReleases',
            },
            {
              payload: releases,
              type: 'receiveReleasesSuccess',
            },
          ],
          done,
        );
      });
    });

    describe('error', () => {
      beforeEach(() => {
        mock.onGet('endpoint.json').replyOnce(500);
      });

      it('dispatches requestReleases and receiveReleasesError ', done => {
        testAction(
          fetchReleases,
          null,
          mockedState,
          [],
          [
            {
              type: 'requestReleases',
            },
            {
              type: 'receiveReleasesError',
            },
          ],
          done,
        );
      });
    });
  });

  describe('receiveReleasesSuccess', () => {
    it('should commit RECEIVE_RELEASES_SUCCESS mutation', done => {
      testAction(
        receiveReleasesSuccess,
        releases,
        mockedState,
        [{ type: types.RECEIVE_RELEASES_SUCCESS, payload: releases }],
        [],
        done,
      );
    });
  });

  describe('receiveReleasesError', () => {
    it('should commit RECEIVE_RELEASES_ERROR mutation', done => {
      testAction(
        receiveReleasesError,
        null,
        mockedState,
        [{ type: types.RECEIVE_RELEASES_ERROR }],
        [],
        done,
      );
    });
  });
});
