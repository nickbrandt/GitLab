import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { TEST_HOST } from 'spec/test_constants';
import testAction from 'helpers/vuex_action_helper';

import createState from 'ee/security_configuration/modules/configuration/state';
import * as types from 'ee/security_configuration/modules/configuration/mutation_types';
import * as actions from 'ee/security_configuration/modules/configuration/actions';

describe('security configuration module actions', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('setSecurityConfigurationEndpoint', () => {
    const securityConfigurationPath = 123;

    it('should commit the SET_SECURITY_CONFIGURATION_ENDPOINT mutation', async () => {
      await testAction(
        actions.setSecurityConfigurationEndpoint,
        securityConfigurationPath,
        state,
        [
          {
            type: types.SET_SECURITY_CONFIGURATION_ENDPOINT,
            payload: securityConfigurationPath,
          },
        ],
        [],
      );
    });
  });

  describe('fetchSecurityConfiguration', () => {
    let mock;
    const configuration = {};

    beforeEach(() => {
      state.securityConfigurationPath = `${TEST_HOST}/-/security/configuration.json`;
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      beforeEach(() => {
        mock.onGet(state.securityConfigurationPath).replyOnce(200, configuration);
      });

      it('should commit the request and success mutations', async () => {
        await testAction(
          actions.fetchSecurityConfiguration,
          {},
          state,
          [
            { type: types.REQUEST_SECURITY_CONFIGURATION },
            {
              type: types.RECEIVE_SECURITY_CONFIGURATION_SUCCESS,
              payload: configuration,
            },
          ],
          [],
        );
      });
    });

    describe('without securityConfigurationPath set', () => {
      beforeEach(() => {
        mock.onGet(state.securityConfigurationPath).replyOnce(200, configuration);
      });

      it('should commit RECEIVE_SECURITY_CONFIGURATION_ERROR mutation', async () => {
        state.securityConfigurationPath = '';

        await testAction(
          actions.fetchSecurityConfiguration,
          {},
          state,
          [
            {
              type: types.RECEIVE_SECURITY_CONFIGURATION_ERROR,
            },
          ],
          [],
        );
      });
    });

    describe('with server error', () => {
      beforeEach(() => {
        mock.onGet(state.securityConfigurationPath).replyOnce(404);
      });

      it('should commit REQUEST_SECURITY_CONFIGURATION and RECEIVE_SECURITY_CONFIGURATION_ERRORmutation', async () => {
        await testAction(
          actions.fetchSecurityConfiguration,
          {},
          state,
          [
            { type: types.REQUEST_SECURITY_CONFIGURATION },
            {
              type: types.RECEIVE_SECURITY_CONFIGURATION_ERROR,
            },
          ],
          [],
        );
      });
    });
  });
});
