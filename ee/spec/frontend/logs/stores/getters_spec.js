import * as getters from 'ee/logs/stores/getters';
import logsPageState from 'ee/logs/stores/state';

import { mockLines } from '../mock_data';

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
        state.logs.lines = mockLines;
      });

      it('returns an empty string', () => {
        expect(getters.trace(state)).toEqual(mockLines.join('\n'));
      });
    });
  });
});
