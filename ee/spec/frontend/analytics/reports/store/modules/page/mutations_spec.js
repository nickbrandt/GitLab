import * as types from 'ee/analytics/reports/store/modules/page/mutation_types';
import mutations from 'ee/analytics/reports/store/modules/page/mutations';
import { initialState, pageData, configData } from 'ee_jest/analytics/reports/mock_data';

describe('Reports page mutations', () => {
  let state;

  beforeEach(() => {
    state = initialState;
  });

  afterEach(() => {
    state = null;
  });

  it.each`
    mutation                                | stateKey       | value
    ${types.REQUEST_PAGE_CONFIG_DATA}       | ${'isLoading'} | ${true}
    ${types.RECEIVE_PAGE_CONFIG_DATA_ERROR} | ${'isLoading'} | ${false}
  `('$mutation will set $stateKey=$value', ({ mutation, stateKey, value }) => {
    mutations[mutation](state);

    expect(state[stateKey]).toEqual(value);
  });

  it.each`
    mutation                                  | payload       | expectedState
    ${types.SET_INITIAL_PAGE_DATA}            | ${pageData}   | ${pageData}
    ${types.RECEIVE_PAGE_CONFIG_DATA_SUCCESS} | ${configData} | ${{ config: configData, isLoading: false }}
  `(
    '$mutation with payload $payload will update state with $expectedState',
    ({ mutation, payload, expectedState }) => {
      mutations[mutation](state, payload);

      expect(state).toMatchObject(expectedState);
    },
  );
});
