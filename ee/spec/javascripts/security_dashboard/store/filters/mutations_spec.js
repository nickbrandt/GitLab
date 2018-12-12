import createState from 'ee/security_dashboard/store/modules/filters/state';
import * as types from 'ee/security_dashboard/store/modules/filters/mutation_types';
import mutations from 'ee/security_dashboard/store/modules/filters/mutations';

describe('filters module mutations', () => {
  describe('SET_FILTER', () => {
    let state;
    let typeFilter;
    let sastOption;
    let allOption;

    beforeEach(() => {
      state = createState();
      [typeFilter] = state.filters;
      [allOption, sastOption] = typeFilter.options;

      const filterId = typeFilter.id;
      const optionId = sastOption.id;

      mutations[types.SET_FILTER](state, { filterId, optionId });
    });

    it('should make SAST the selected option', () => {
      expect(sastOption.selected).toEqual(true);
    });

    it('should remove ALL as the selected option', () => {
      expect(allOption.selected).toEqual(false);
    });
  });
});
