import * as getters from 'ee/logs/stores/getters';
import logsPageState from 'ee/logs/stores/state';

import { mockLogsResult, mockTrace } from '../mock_data';

describe('Logs Store getters', () => {
  let state;

  beforeEach(() => {
    state = logsPageState();
  });

  describe('trace', () => {
    describe('when state is initialized', () => {
      it('returns an empty string', () => {
        expect(getters.trace(state)).toEqual('');
      });
    });

    describe('when state logs are empty', () => {
      beforeEach(() => {
        state.logs.lines = [];
      });

      it('returns an empty string', () => {
        expect(getters.trace(state)).toEqual('');
      });
    });

    describe('when state logs are set', () => {
      beforeEach(() => {
        state.logs.lines = mockLogsResult;
      });

      it('returns an empty string', () => {
        expect(getters.trace(state)).toEqual(mockTrace.join('\n'));
      });
    });
  });
});
