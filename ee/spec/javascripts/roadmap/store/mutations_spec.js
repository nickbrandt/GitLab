import mutations from 'ee/roadmap/store/mutations';
import * as types from 'ee/roadmap/store/mutation_types';

describe('Roadmap Store Mutations', () => {
  describe('SET_INITIAL_DATA', () => {
    it('Should set initial Roadmap data to state', () => {
      const state = {};
      const mockData = {
        foo: 'bar',
        bar: 'baz',
      };

      mutations[types.SET_INITIAL_DATA](state, mockData);

      expect(state).toEqual(mockData);
    });
  });
});
