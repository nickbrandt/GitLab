import createState from 'ee/security_dashboard/store/modules/filters/state';
import * as types from 'ee/security_dashboard/store/modules/filters/mutation_types';
import mutations from 'ee/security_dashboard/store/modules/filters/mutations';

describe('filters module mutations', () => {
  describe('SET_FILTER', () => {
    let state;
    let typeFilter;
    let sastOption;

    beforeEach(() => {
      state = createState();
      [typeFilter] = state.filters;
      [, sastOption] = typeFilter.options;

      mutations[types.SET_FILTER](state, {
        filterId: typeFilter.id,
        optionId: sastOption.id,
      });
    });

    it('should make SAST the selected option', () => {
      expect(state.filters[0].options[1].selected).toEqual(true);
    });

    it('should remove ALL as the selected option', () => {
      expect(state.filters[0].options[0].selected).toEqual(false);
    });
  });
});
