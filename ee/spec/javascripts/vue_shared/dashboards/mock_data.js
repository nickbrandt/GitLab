import { TEST_HOST } from 'spec/test_constants';

const AVATAR_URL = `${TEST_HOST}/dummy.jpg`;

export default function mockPipelineData(
  status = 'success',
  id = 1,
  finishedTimeStamp = new Date(Date.now() - 86400000).toISOString(),
  isTag = false,
) {
  return {
    id,
    user: {
      id: 1,
      name: 'Test',
      username: 'test',
      state: 'active',
      avatar_url: AVATAR_URL,
      web_url: '/test',
      status_tooltip_html: null,
      path: '/test',
    },
    active: false,
    path: '/test/test-project/pipelines/1',
    details: {
      status: {
        icon: `status_${status}`,
        text: status,
        label: status,
        group: status,
        tooltip: status,
        has_details: true,
        details_path: '/test/test-project/pipelines/1',
        illustration: null,
      },
      finished_at: finishedTimeStamp,
    },
    ref: {
      name: 'master',
      path: 'test/test-project/commits/master',
      tag: isTag,
      branch: true,
      merge_request: false,
    },
    commit: {
      id: 'e778416d94deaf75bdabcc8fdd6b7d21f482bcca',
      short_id: 'e778416d',
      title: "Add new file to the branch I'm working on",
      message: "Add new file to the branch I'm working on",
      author: {
        id: 1,
        name: 'Test',
        username: 'test',
        state: 'active',
        avatar_url: AVATAR_URL,
        status_tooltip_html: null,
        path: '/test',
      },
      commit_url: '/test/test-project/commit/e778416d94deaf75bdabcc8fdd6b7d21f482bcca',
      commit_path: '/test/test-project/commit/e778416d94deaf75bdabcc8fdd6b7d21f482bcca',
    },
    project: {
      full_name: 'Test / test-project',
      full_path: '/test/test-project',
      name: 'test-project',
    },
  };
}
