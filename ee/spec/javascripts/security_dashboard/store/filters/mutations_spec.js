import createState from 'ee/security_dashboard/store/modules/filters/state';
import * as types from 'ee/security_dashboard/store/modules/filters/mutation_types';
import mutations from 'ee/security_dashboard/store/modules/filters/mutations';

describe('filters module mutations', () => {
  describe('SET_FILTER', () => {
    let state;
    let severityFilter;
    let criticalOption;
    let highOption;

    beforeEach(() => {
      state = createState();
      [severityFilter] = state.filters;
      [, criticalOption, highOption] = severityFilter.options;

      mutations[types.SET_FILTER](state, {
        filterId: severityFilter.id,
        optionId: criticalOption.id,
      });
    });

    it('should make critical the selected option', () => {
      expect(state.filters[0].options[1].selected).toEqual(true);
    });

    it('should remove ALL as the selected option', () => {
      expect(state.filters[0].options[0].selected).toEqual(false);
    });

    describe('on subsequent changes', () => {
      it('should add "high" to the selected options', () => {
        mutations[types.SET_FILTER](state, {
          filterId: severityFilter.id,
          optionId: highOption.id,
        });

        expect(state.filters[0].options[1].selected).toEqual(true);
        expect(state.filters[0].options[2].selected).toEqual(true);
      });
    });
  });

  describe('SET_FILTER_OPTIONS', () => {
    let state;
    let firstFilter;
    const options = [{ id: 0, name: 'c' }, { id: 3, name: 'c' }];

    beforeEach(() => {
      state = createState();
      [firstFilter] = state.filters;
      const filterId = firstFilter.id;

      mutations[types.SET_FILTER_OPTIONS](state, { filterId, options });
    });

    it('should add all the options to the type filter', () => {
      expect(firstFilter.options).toEqual(options);
    });
  });
});
