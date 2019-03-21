import * as actions from 'ee/roadmap/store/actions';

import testAction from 'spec/helpers/vuex_action_helper';

describe('Roadmap Vuex Actions', () => {
  describe('setInitialData', () => {
    it('Should set initial roadmap props', done => {
      const mockRoadmap = {
        foo: 'bar',
        bar: 'baz',
      };

      testAction(
        actions.setInitialData,
        mockRoadmap,
        {},
        [{ type: 'SET_INITIAL_DATA', payload: mockRoadmap }],
        [],
        done,
      );
    });
  });
});
