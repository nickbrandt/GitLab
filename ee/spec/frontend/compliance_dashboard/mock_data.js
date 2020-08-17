const twoDaysAgo = () => {
  const date = new Date();
  date.setDate(date.getDate() - 2);
  return date.toISOString();
};

const createUser = id => ({
  id,
  avatar_url: `https://${id}`,
  name: `User ${id}`,
  state: 'active',
  username: `user-${id}`,
  web_url: `http://localhost:3000/user-${id}`,
});

export const createPipelineStatus = status => ({
  details_path: '/h5bp/html5-boilerplate/pipelines/58',
  favicon: '',
  group: status,
  has_details: true,
  icon: `status_${status}`,
  illustration: null,
  label: status,
  text: status,
  tooltip: status,
});

export const createMergeRequest = ({ id = 1, props } = {}) => {
  const mergeRequest = {
    id,
    approved_by_users: [],
    issuable_reference: '!1',
    merged_at: twoDaysAgo(),
    milestone: null,
    path: `/h5bp/html5-boilerplate/-/merge_requests/${id}`,
    title: `Merge request ${id}`,
    author: createUser(id),
    pipeline_status: createPipelineStatus('success'),
    approval_status: 'success',
  };

  return { ...mergeRequest, ...props };
};

export const createApprovers = count => {
  return Array(count)
    .fill()
    .map((_, id) => createUser(id));
};

export const createMergeRequests = ({ count = 1, props = {} } = {}) => {
  return Array(count)
    .fill()
    .map((_, id) =>
      createMergeRequest({
        id,
        props,
      }),
    );
};
