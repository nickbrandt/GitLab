import mutations from 'ee/audit_events/store/mutations';
import * as types from 'ee/audit_events/store/mutation_types';

describe('Audit Event mutations', () => {
  let state = null;
  const startDate = new Date('March 13, 2020 12:00:00');
  const endDate = new Date('April 13, 2020 12:00:00');

  beforeEach(() => {
    state = {};
  });

  afterEach(() => {
    state = null;
  });

  it.each`
    mutation                  | payload                      | expectedState
    ${types.SET_FILTER_VALUE} | ${{ id: '1', type: 'user' }} | ${{ filterValue: { id: '1', type: 'user' } }}
    ${types.SET_DATE_RANGE}   | ${{ startDate, endDate }}    | ${{ startDate, endDate }}
    ${types.SET_SORT_BY}      | ${'created_asc'}             | ${{ sortBy: 'created_asc' }}
  `(
    '$mutation with payload $payload will update state with $expectedState',
    ({ mutation, payload, expectedState }) => {
      state = {};
      mutations[mutation](state, payload);

      expect(state).toMatchObject(expectedState);
    },
  );

  describe(`${types.INITIALIZE_AUDIT_EVENTS}`, () => {
    const payload = {
      entity_id: '1',
      entity_type: 'user',
      created_after: startDate,
      created_before: endDate,
      sort: 'created_asc',
    };

    it.each`
      stateKey         | expectedState
      ${'filterValue'} | ${{ id: payload.entity_id, type: payload.entity_type }}
      ${'startDate'}   | ${payload.created_after}
      ${'endDate'}     | ${payload.created_before}
      ${'sortBy'}      | ${payload.sort}
    `('state.$stateKey should be set to $expectedState', ({ stateKey, expectedState }) => {
      state = {};
      mutations[types.INITIALIZE_AUDIT_EVENTS](state, payload);

      expect(state[stateKey]).toEqual(expectedState);
    });
  });
});
