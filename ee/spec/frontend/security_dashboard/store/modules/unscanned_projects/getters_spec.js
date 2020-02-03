import * as getters from 'ee/security_dashboard/store/modules/unscanned_projects/getters';

import { UNSCANNED_PROJECTS_DATE_RANGES } from 'ee/security_dashboard/store/constants';
import { groupByDateRanges } from 'ee/security_dashboard/store/modules/unscanned_projects/utils';

jest.mock('ee/security_dashboard/store/modules/unscanned_projects/utils', () => ({
  groupByDateRanges: jest.fn(),
}));

describe('Unscanned projects getters', () => {
  describe('untestedProjects', () => {
    it('takes an array of projects and returns only projects that have "securityTestsUnconfigured" set to be "true"', () => {
      const projects = [
        { securityTestsUnconfigured: null },
        { securityTestsUnconfigured: true },
        { securityTestsUnconfigured: false },
        { securityTestsUnconfigured: true },
        {},
      ];

      expect(getters.untestedProjects({ projects })).toStrictEqual([projects[1], projects[3]]);
    });
  });

  describe('untestedProjectsCount', () => {
    it('returns the amount of untestedProjects', () => {
      const untestedProjects = [{}, {}, {}];

      expect(getters.untestedProjectsCount({}, { untestedProjects })).toBe(untestedProjects.length);
    });
  });

  describe('outdatedProjects', () => {
    it('groups the given projects by date ranges', () => {
      const projects = [];
      const mockReturnValue = [];

      groupByDateRanges.mockReturnValueOnce(mockReturnValue);

      const result = getters.outdatedProjects({ projects });

      expect(groupByDateRanges).toHaveBeenCalledTimes(1);
      expect(groupByDateRanges).toHaveBeenCalledWith({
        ranges: UNSCANNED_PROJECTS_DATE_RANGES,
        datePropName: 'securityTestsLastSuccessfulRun',
        projects,
      });

      expect(result).toBe(mockReturnValue);
    });
  });

  describe('outdatedProjectsCount', () => {
    it('returns the amount of outdated projects', () => {
      const dateRangeOne = [{}, {}];
      const dateRangeTwo = [{}];
      const outdatedProjects = [{ projects: dateRangeOne }, { projects: dateRangeTwo }];

      expect(getters.outdatedProjectsCount({}, { outdatedProjects })).toBe(
        dateRangeOne.length + dateRangeTwo.length,
      );
    });
  });
});
