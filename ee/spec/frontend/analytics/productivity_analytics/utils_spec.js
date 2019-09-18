import {
  getLabelsEndpoint,
  getMilestonesEndpoint,
} from 'ee/analytics/productivity_analytics/utils';

describe('Productivity Analytics utils', () => {
  const namespacePath = 'gitlab-org';
  const projectWithNamespace = 'gitlab-org/gitlab-test';

  describe('getLabelsEndpoint', () => {
    it('returns the group labels path when no project is given', () => {
      expect(getLabelsEndpoint(namespacePath)).toBe('/groups/gitlab-org/-/labels');
    });

    it('returns the project labels path when a project is given', () => {
      expect(getLabelsEndpoint(namespacePath, projectWithNamespace)).toBe(
        '/gitlab-org/gitlab-test/-/labels',
      );
    });
  });

  describe('getMilestonesEndpoint', () => {
    it('returns the group milestone path when no project is given', () => {
      expect(getMilestonesEndpoint(namespacePath)).toBe('/groups/gitlab-org/-/milestones');
    });

    it('returns the project milestone path when a project is given', () => {
      expect(getMilestonesEndpoint(namespacePath, projectWithNamespace)).toBe(
        '/gitlab-org/gitlab-test/-/milestones',
      );
    });
  });
});
