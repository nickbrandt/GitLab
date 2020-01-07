// eslint-disable-next-line import/prefer-default-export
export const mergeRequests = [
  {
    title:
      'This is just a super long merge request title that does not fit into one line so it needs to be truncated',
    iid: 12345,
    web_url: 'https://gitlab.com/gitlab-org/gitlab/merge_requests/38062',
    created_at: '2020-01-08',
    milestone: {
      id: 123,
      iid: 1234,
      title: '11.1',
      web_url: 'https://gitlab.com/gitlab-org/gitlab/merge_requests?milestone_title=12.7',
      due_date: '2020-01-31',
    },
    review_time: 64,
    author: {
      id: 123,
      username: 'foo',
      name: 'foo',
      web_url: 'https://gitlab.com/foo',
      avatar_url: '',
    },
    approved_by: [
      {
        id: 123,
        username: 'bar',
        name: 'bar',
        web_url: 'https://gitlab.com/bar',
        avatar_url: '',
      },
    ],
    notes_count: 21,
    diff_stats: { additions: 504, deletions: 10, total: 514, commits_count: 7 },
  },
];
