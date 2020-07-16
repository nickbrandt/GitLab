import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import httpStatusCodes from '~/lib/utils/http_status';
import createFlash from '~/flash';
import testAction from 'helpers/vuex_action_helper';
import * as actions from 'ee/analytics/reports/store/modules/page/actions';
import { initialState, pageData, configData } from 'ee_jest/analytics/reports/mock_data';

jest.mock('~/flash');

describe('Reports page actions', () => {
  let state;
  let mock;

  beforeEach(() => {
    state = initialState;
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    state = null;
    mock.restore();
  });

  it.each`
    action                            | type                                  | payload
    ${'setInitialPageData'}           | ${'SET_INITIAL_PAGE_DATA'}            | ${pageData}
    ${'requestPageConfigData'}        | ${'REQUEST_PAGE_CONFIG_DATA'}         | ${null}
    ${'receivePageConfigDataSuccess'} | ${'RECEIVE_PAGE_CONFIG_DATA_SUCCESS'} | ${configData}
    ${'receivePageConfigDataError'}   | ${'RECEIVE_PAGE_CONFIG_DATA_ERROR'}   | ${null}
  `('$action commits mutation $type with $payload', ({ action, type, payload }) => {
    return testAction(
      actions[action],
      payload,
      state,
      [payload ? { type, payload } : { type }],
      [],
    );
  });

  describe('receivePageConfigDataError', () => {
    it('displays an error message', () => {
      actions.receivePageConfigDataError({ commit: jest.fn() });

      expect(createFlash).toHaveBeenCalledWith(
        'There was an error while fetching configuration data.',
      );
    });
  });

  describe('fetchPageConfigData', () => {
    describe('success', () => {
      beforeEach(() => {
        mock.onGet().reply(httpStatusCodes.OK, configData);
      });

      it('dispatches the "requestPageConfigData" and "receivePageConfigDataSuccess" actions', () => {
        return testAction(
          actions.fetchPageConfigData,
          null,
          state,
          [],
          [
            { type: 'requestPageConfigData' },
            { type: 'receivePageConfigDataSuccess', payload: configData },
          ],
        );
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        mock.onGet().reply(httpStatusCodes.NOT_FOUND);
      });

      it('dispatches the "requestPageConfigData" and "receivePageConfigDataError" actions', () => {
        return testAction(
          actions.fetchPageConfigData,
          null,
          state,
          [],
          [{ type: 'requestPageConfigData' }, { type: 'receivePageConfigDataError' }],
        );
      });
    });
  });
});
