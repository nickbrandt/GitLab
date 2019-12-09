import createState from 'ee/analytics/productivity_analytics/store/modules/filters/state';
import * as getters from 'ee/analytics/productivity_analytics/store/modules/filters/getters';
import { chartKeys } from 'ee/analytics/productivity_analytics/constants';

describe('Productivity analytics filter getters', () => {
  let state;
  const currentYear = new Date().getFullYear();
  const startDate = new Date(currentYear, 8, 1);
  const endDate = new Date(currentYear, 8, 7);

  beforeEach(() => {
    state = createState();
  });

  describe('getCommonFilterParams', () => {
    beforeEach(() => {
      state = {
        groupNamespace: 'gitlab-org',
        projectPath: 'gitlab-org/gitlab-test',
        authorUsername: 'root',
        milestoneTitle: 'foo',
        labelName: ['labelxyz'],
        startDate,
        endDate,
      };
    });

    describe('when chart is not scatterplot', () => {
      it('returns an object with common filter params', () => {
        const expected = {
          author_username: 'root',
          group_id: 'gitlab-org',
          label_name: ['labelxyz'],
          merged_at_after: '2019-09-01T00:00:00Z',
          merged_at_before: '2019-09-07T23:59:59Z',
          milestone_title: 'foo',
          project_id: 'gitlab-org/gitlab-test',
        };

        const result = getters.getCommonFilterParams(state)(chartKeys.main);

        expect(result).toEqual(expected);
      });
    });

    describe('when chart is scatterplot', () => {
      it('returns an object with common filter params and subtracts 30 days from the merged_at_after date', () => {
        const expected = {
          author_username: 'root',
          group_id: 'gitlab-org',
          label_name: ['labelxyz'],
          merged_at_after: '2019-08-02T00:00:00Z',
          merged_at_before: '2019-09-07T23:59:59Z',
          milestone_title: 'foo',
          project_id: 'gitlab-org/gitlab-test',
        };

        const result = getters.getCommonFilterParams(state)(chartKeys.scatterplot);

        expect(result).toEqual(expected);
      });
    });
  });
});
