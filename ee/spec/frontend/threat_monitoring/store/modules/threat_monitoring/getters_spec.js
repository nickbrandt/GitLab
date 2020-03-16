import createState from 'ee/threat_monitoring/store/modules/threat_monitoring/state';
import * as getters from 'ee/threat_monitoring/store/modules/threat_monitoring/getters';
import { INVALID_CURRENT_ENVIRONMENT_NAME, TIME_WINDOWS } from 'ee/threat_monitoring/constants';

describe('threatMonitoring module getters', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('currentEnvironmentName', () => {
    describe.each`
      context                            | currentEnvironmentId | environments                | expectedName
      ${'no environments'}               | ${1}                 | ${[]}                       | ${INVALID_CURRENT_ENVIRONMENT_NAME}
      ${'a non-existent environment id'} | ${2}                 | ${[{ id: 1 }]}              | ${INVALID_CURRENT_ENVIRONMENT_NAME}
      ${'an existing environment id'}    | ${3}                 | ${[{ id: 3, name: 'foo' }]} | ${'foo'}
    `('given $context', ({ currentEnvironmentId, environments, expectedName }) => {
      beforeEach(() => {
        state.currentEnvironmentId = currentEnvironmentId;
        state.environments = environments;
      });

      it('returns the expected name', () => {
        expect(getters.currentEnvironmentName(state)).toBe(expectedName);
      });
    });
  });

  describe('currentTimeWindowName', () => {
    it('gives the correct name for a valid time window', () => {
      Object.keys(TIME_WINDOWS).forEach(timeWindow => {
        state.currentTimeWindow = timeWindow;
        expect(getters.currentTimeWindowName(state)).toBe(TIME_WINDOWS[timeWindow].name);
      });
    });

    it('gives the default name for an invalid time window', () => {
      state.currentTimeWindowName = 'foo';
      expect(getters.currentTimeWindowName(state)).toBe('30 days');
    });
  });
});
