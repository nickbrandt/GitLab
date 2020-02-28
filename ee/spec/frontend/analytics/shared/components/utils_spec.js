import {
  buildGroupFromDataset,
  buildProjectFromDataset,
  buildCycleAnalyticsInitialData,
} from 'ee/analytics/shared/utils';

const groupDataset = {
  groupId: '1',
  groupName: 'My Group',
  groupFullPath: 'my-group',
  groupAvatarUrl: 'foo/bar',
};

const projectDataset = {
  projectId: '1',
  projectName: 'My Project',
  projectPathWithNamespace: 'my-group/my-project',
};

const rawProjects = JSON.stringify([
  {
    project_id: '1',
    project_name: 'My Project',
    project_path_with_namespace: 'my-group/my-project',
  },
]);

describe('buildGroupFromDataset', () => {
  it('returns null if groupId is missing', () => {
    expect(buildGroupFromDataset({ foo: 'bar' })).toBeNull();
  });

  it('returns a group object when the groupId is given', () => {
    expect(buildGroupFromDataset(groupDataset)).toEqual({
      id: 1,
      name: 'My Group',
      full_path: 'my-group',
      avatar_url: 'foo/bar',
    });
  });
});

describe('buildProjectFromDataset', () => {
  it('returns null if projectId is missing', () => {
    expect(buildProjectFromDataset({ foo: 'bar' })).toBeNull();
  });

  it('returns a project object when the projectId is given', () => {
    expect(buildProjectFromDataset(projectDataset)).toEqual({
      id: 1,
      name: 'My Project',
      path_with_namespace: 'my-group/my-project',
      avatar_url: undefined,
    });
  });
});

describe('buildCycleAnalyticsInitialData', () => {
  it.each`
    field                 | value
    ${'group'}            | ${null}
    ${'createdBefore'}    | ${null}
    ${'createdAfter'}     | ${null}
    ${'selectedProjects'} | ${[]}
  `('will set a default value for "$field" if is not present', ({ field, value }) => {
    expect(buildCycleAnalyticsInitialData()).toMatchObject({
      [field]: value,
    });
  });

  describe('group', () => {
    it("will be set given a valid 'groupId' and all group parameters", () => {
      expect(buildCycleAnalyticsInitialData(groupDataset)).toMatchObject({
        group: { avatarUrl: 'foo/bar', fullPath: 'my-group', id: 1, name: 'My Group' },
      });
    });

    it.each`
      field          | value
      ${'avatarUrl'} | ${null}
      ${'fullPath'}  | ${null}
      ${'name'}      | ${null}
    `("will be $value if the '$field' field is not present", ({ field, value }) => {
      expect(buildCycleAnalyticsInitialData({ groupId: groupDataset.groupId })).toMatchObject({
        group: { id: 1, [field]: value },
      });
    });
  });

  describe('selectedProjects', () => {
    it('will be set given an array of projects', () => {
      expect(buildCycleAnalyticsInitialData({ projects: rawProjects })).toMatchObject({
        selectedProjects: [
          {
            projectId: '1',
            projectName: 'My Project',
            projectPathWithNamespace: 'my-group/my-project',
          },
        ],
      });
    });

    it.each`
      field                 | value
      ${'selectedProjects'} | ${null}
      ${'selectedProjects'} | ${[]}
      ${'selectedProjects'} | ${''}
    `('will be an empty array if given a value of `$value`', ({ value, field }) => {
      expect(buildCycleAnalyticsInitialData({ projects: value })).toMatchObject({
        [field]: [],
      });
    });
  });

  describe.each`
    field              | value
    ${'createdBefore'} | ${'2019-12-31'}
    ${'createdAfter'}  | ${'2019-10-31'}
  `('$field', ({ field, value }) => {
    it('given a valid date, will return a date object', () => {
      expect(buildCycleAnalyticsInitialData({ [field]: value })).toMatchObject({
        [field]: new Date(value),
      });
    });

    it('will return null if omitted', () => {
      expect(buildCycleAnalyticsInitialData()).toMatchObject({ [field]: null });
    });
  });
});
