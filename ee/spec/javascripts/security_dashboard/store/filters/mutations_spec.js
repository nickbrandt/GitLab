import createState from 'ee/security_dashboard/store/modules/filters/state';
import * as types from 'ee/security_dashboard/store/modules/filters/mutation_types';
import mutations from 'ee/security_dashboard/store/modules/filters/mutations';

describe('filters module mutations', () => {
  let state;
  let severityFilter;
  let criticalOption;
  let highOption;

  beforeEach(() => {
    state = createState();
    [severityFilter] = state.filters;
    [, criticalOption, highOption] = severityFilter.options;
  });

  describe('SET_FILTER', () => {
    beforeEach(() => {
      mutations[types.SET_FILTER](state, {
        filterId: severityFilter.id,
        optionId: criticalOption.id,
      });
    });

    it('should make critical the selected option', () => {
      expect(state.filters[0].selection).toEqual(new Set(['critical']));
    });

    it('should set to `all` if no option is selected', () => {
      mutations[types.SET_FILTER](state, {
        filterId: severityFilter.id,
        optionId: criticalOption.id,
      });

      expect(state.filters[0].selection).toEqual(new Set(['all']));
    });

    describe('on subsequent changes', () => {
      it('should add "high" to the selected options', () => {
        mutations[types.SET_FILTER](state, {
          filterId: severityFilter.id,
          optionId: highOption.id,
        });

        expect(state.filters[0].selection).toEqual(new Set(['high', 'critical']));
      });
    });
  });

  describe('SET_FILTER_OPTIONS', () => {
    const options = [{ id: 0, name: 'c' }, { id: 3, name: 'c' }];

    beforeEach(() => {
      const filterId = severityFilter.id;

      mutations[types.SET_FILTER_OPTIONS](state, { filterId, options });
    });

    it('should add all the options to the type filter', () => {
      expect(severityFilter.options).toEqual(options);
    });
  });
});
