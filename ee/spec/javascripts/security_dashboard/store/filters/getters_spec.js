import createState from 'ee/security_dashboard/store/modules/filters/state';
import * as getters from 'ee/security_dashboard/store/modules/filters/getters';

describe('filters module getters', () => {
  const mockedGetters = state => {
    const getFilter = filterId => getters.getFilter(state)(filterId);
    const getSelectedOptions = filterId =>
      getters.getSelectedOptions(state, { getFilter })(filterId);

    return {
      getFilter,
      getSelectedOptions,
    };
  };

  describe('getFilter', () => {
    it('should return the type filter information', () => {
      const state = createState();
      const typeFilter = getters.getFilter(state)('type');

      expect(typeFilter.name).toEqual('Report type');
    });
  });

  describe('getSelectedOptions', () => {
    it('should return "SAST" as the selcted option', () => {
      const state = createState();
      const selectedOptions = getters.getSelectedOptions(state, mockedGetters(state))('type');

      expect(selectedOptions).toHaveLength(1);
      expect(selectedOptions[0].name).toEqual('SAST');
    });
  });

  describe('activeFilters', () => {
    it('should return no severity filters', () => {
      const state = createState();
      const activeFilters = getters.activeFilters(state, mockedGetters(state));

      expect(activeFilters.severity).toHaveLength(0);
    });

    it('should return the SAST type filter', () => {
      const state = createState();
      const activeFilters = getters.activeFilters(state, mockedGetters(state));

      expect(activeFilters.type).toHaveLength(1);
      expect(activeFilters.type[0]).toEqual('sast');
    });

    it('should return multiple project filters"', () => {
      const state = createState();
      const projectFilter = {
        id: 'project',
        options: [{ id: 'one', selected: true }, { id: 'anotherone', selected: true }],
      };
      state.filters.push(projectFilter);
      const activeFilters = getters.activeFilters(state, mockedGetters(state));

      expect(activeFilters.project).toHaveLength(2);
    });
  });
});
