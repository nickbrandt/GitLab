import createState from 'ee/analytics/productivity_analytics/store/modules/filters/state';
import * as getters from 'ee/analytics/productivity_analytics/store/modules/filters/getters';

describe('Productivity analytics filter getters', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('getCommonFilterParams', () => {
    it('returns an object with group_id, project_id and all relevant params from the filters string', () => {
      state = {
        groupNamespace: 'gitlab-org',
        projectPath: 'gitlab-org/gitlab-test',
        filters: '?author_username=root&milestone_title=foo&label_name[]=labelxyz',
      };

      const mockGetters = { mergedOnAfterDate: '2019-07-16T00:00:00.00Z' };
      const expected = {
        author_username: 'root',
        group_id: 'gitlab-org',
        label_name: ['labelxyz'],
        merged_at_after: '2019-07-16T00:00:00.00Z',
        milestone_title: 'foo',
        project_id: 'gitlab-org/gitlab-test',
      };

      const result = getters.getCommonFilterParams(state, mockGetters);

      expect(result).toEqual(expected);
    });
  });

  describe('mergedOnAfterDate', () => {
    beforeEach(() => {
      const mockedTimestamp = 1563235200000; // 2019-07-16T00:00:00.00Z
      jest.spyOn(Date.prototype, 'getTime').mockReturnValue(mockedTimestamp);
    });
    it('returns the correct date in the past', () => {
      state = {
        daysInPast: 90,
      };

      const mergedOnAfterDate = getters.mergedOnAfterDate(state);

      expect(mergedOnAfterDate).toBe('2019-04-17T00:00:00.000Z');
    });
  });
});
