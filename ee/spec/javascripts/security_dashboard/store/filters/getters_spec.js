import createState from 'ee/security_dashboard/store/modules/filters/state';
import * as getters from 'ee/security_dashboard/store/modules/filters/getters';

describe('filters module getters', () => {
  const mockedGetters = state => {
    const getFilter = filterId => getters.getFilter(state)(filterId);
    const getSelectedOptions = filterId =>
      getters.getSelectedOptions(state, { getFilter })(filterId);
    const getSelectedOptionIds = filterId =>
      getters.getSelectedOptionIds(state, { getSelectedOptions })(filterId);
    const getFilterIds = getters.getFilterIds(state);

    return {
      getFilter,
      getSelectedOptions,
      getSelectedOptionIds,
      getFilterIds,
    };
  };

  describe('getFilter', () => {
    it('should return the type filter information', () => {
      const state = createState();
      const typeFilter = getters.getFilter(state)('report_type');

      expect(typeFilter.name).toEqual('Report type');
    });
  });

  describe('getSelectedOptions', () => {
    describe('with one selected option', () => {
      it('should return "All" as the selected option', () => {
        const state = createState();
        const selectedOptions = getters.getSelectedOptions(state, mockedGetters(state))(
          'report_type',
        );

        expect(selectedOptions).toHaveLength(1);
        expect(selectedOptions[0].name).toEqual('All');
      });
    });

    describe('with multiple selected options', () => {
      it('should return both "High" and "Critical" ', () => {
        const state = {
          filters: [
            {
              id: 'severity',
              options: [{ id: 'critical', selected: true }, { id: 'high', selected: true }],
            },
          ],
        };
        const selectedOptions = getters.getSelectedOptions(state, mockedGetters(state))('severity');

        expect(selectedOptions).toHaveLength(2);
      });
    });
  });

  describe('getSelectedOptionIds', () => {
    it('should return "one" as the selcted project ID', () => {
      const state = createState();
      const projectFilter = {
        id: 'project',
        options: [{ id: 'one', selected: true }, { id: 'anotherone', selected: false }],
      };
      state.filters.push(projectFilter);
      const selectedOptionIds = getters.getSelectedOptionIds(state, mockedGetters(state))(
        'project',
      );

      expect(selectedOptionIds).toHaveLength(1);
      expect(selectedOptionIds[0]).toEqual('one');
    });
  });

  describe('getSelectedOptionNames', () => {
    it('should return "All" as the selected option', () => {
      const state = createState();
      const selectedOptionNames = getters.getSelectedOptionNames(state, mockedGetters(state))(
        'severity',
      );

      expect(selectedOptionNames).toEqual('All');
    });

    it('should return the correct message when multiple filters are selected', () => {
      const state = {
        filters: [
          {
            id: 'severity',
            options: [{ name: 'Critical', selected: true }, { name: 'High', selected: true }],
          },
        ],
      };
      const selectedOptionNames = getters.getSelectedOptionNames(state, mockedGetters(state))(
        'severity',
      );

      expect(selectedOptionNames).toEqual('Critical +1 more');
    });
  });

  describe('activeFilters', () => {
    it('should return no severity filters', () => {
      const state = createState();
      const activeFilters = getters.activeFilters(state, mockedGetters(state));

      expect(activeFilters.severity).toHaveLength(0);
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
