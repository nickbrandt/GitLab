import createState from 'ee/security_dashboard/store/modules/filters/state';
import * as getters from 'ee/security_dashboard/store/modules/filters/getters';

describe('filters module getters', () => {
  const mockedGetters = {};
  mockedGetters.getFilter = filterId => getters.getFilter(createState())(filterId);
  mockedGetters.getSelectedOptions = filterId =>
    getters.getSelectedOptions(createState(), mockedGetters)(filterId);

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
      const selectedOptions = getters.getSelectedOptions(state, mockedGetters)('type');

      expect(selectedOptions).toHaveLength(1);
      expect(selectedOptions[0].name).toEqual('SAST');
    });
  });

  describe('activeFilters', () => {
    it('should return no severity filters', () => {
      const state = createState();
      const activeFilters = getters.activeFilters(state, mockedGetters);

      expect(activeFilters.severity).toHaveLength(0);
    });

    it('should return the SAST type filter', () => {
      const state = createState();
      const activeFilters = getters.activeFilters(state, mockedGetters);

      expect(activeFilters.type).toHaveLength(1);
      expect(activeFilters.type[0]).toEqual('sast');
    });
  });
});
