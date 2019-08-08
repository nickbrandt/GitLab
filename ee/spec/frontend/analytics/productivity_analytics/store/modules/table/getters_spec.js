import createState from 'ee/analytics/productivity_analytics/store/modules/table/state';
import * as getters from 'ee/analytics/productivity_analytics/store/modules/table/getters';
import { tableSortOrder } from 'ee/analytics/productivity_analytics/constants';

describe('Productivity analytics table getters', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('sortIcon', () => {
    it('returns the correct icon when sort order is asc', () => {
      state = {
        sortOrder: tableSortOrder.asc.value,
      };

      expect(getters.sortIcon(state)).toBe('sort-lowest');
    });

    it('returns the correct icon when sort order is desc', () => {
      state = {
        sortOrder: tableSortOrder.desc.value,
      };

      expect(getters.sortIcon(state)).toBe('sort-highest');
    });
  });

  describe('sortTooltipTitle', () => {
    it('returns the correct title when sort order is asc', () => {
      state = {
        sortOrder: tableSortOrder.asc.value,
      };

      expect(getters.sortTooltipTitle(state)).toBe('Ascending');
    });

    it('returns the correct title when sort order is desc', () => {
      state = {
        sortOrder: tableSortOrder.desc.value,
      };

      expect(getters.sortTooltipTitle(state)).toBe('Descending');
    });
  });

  describe('sortFieldDropdownLabel', () => {
    it('returns the correct label for the current sort field', () => {
      state.sortField = 'time_to_last_commit';

      expect(getters.sortFieldDropdownLabel(state)).toBe('Time from first comment to last commit');
    });
  });

  describe('getColumnOptions', () => {
    it('returns an object of key/value pairs with the available column options', () => {
      state.sortFields = {
        time_to_first_comment: 'Time from first commit until first comment',
        time_to_last_commit: 'Time from first comment to last commit',
        time_to_merge: 'Time from last commit to merge',
        days_to_merge: 'Days to merge',
      };

      expect(getters.getColumnOptions(state)).toEqual({
        days_to_merge: 'Days to merge',
        time_to_first_comment: 'Time from first commit until first comment',
        time_to_last_commit: 'Time from first comment to last commit',
      });
    });
  });
});
