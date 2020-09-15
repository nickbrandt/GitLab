export const getProjectIdQueryParams = projects =>
  projects.map(project => `project_ids[]=${project.id}`).join('&');
