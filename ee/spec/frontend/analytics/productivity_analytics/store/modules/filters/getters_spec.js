import createState from 'ee/analytics/productivity_analytics/store/modules/filters/state';
import * as getters from 'ee/analytics/productivity_analytics/store/modules/filters/getters';
import { chartKeys } from 'ee/analytics/productivity_analytics/constants';

describe('Productivity analytics filter getters', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe('getCommonFilterParams', () => {
    beforeEach(() => {
      state = {
        groupNamespace: 'gitlab-org',
        projectPath: 'gitlab-org/gitlab-test',
        filters: '?author_username=root&milestone_title=foo&label_name[]=labelxyz',
        daysInPast: 30,
      };
    });

    describe('when chart is not scatterplot', () => {
      it('returns an object with common filter params', () => {
        const expected = {
          author_username: 'root',
          group_id: 'gitlab-org',
          label_name: ['labelxyz'],
          merged_at_after: '30days',
          milestone_title: 'foo',
          project_id: 'gitlab-org/gitlab-test',
        };

        const result = getters.getCommonFilterParams(state)(chartKeys.main);

        expect(result).toEqual(expected);
      });
    });

    describe('when chart is scatterplot', () => {
      it('returns an object with common filter params and adds additional days to the merged_at_after property', () => {
        const expected = {
          author_username: 'root',
          group_id: 'gitlab-org',
          label_name: ['labelxyz'],
          merged_at_after: '60days',
          milestone_title: 'foo',
          project_id: 'gitlab-org/gitlab-test',
        };

        const result = getters.getCommonFilterParams(state)(chartKeys.scatterplot);

        expect(result).toEqual(expected);
      });
    });
  });
});
