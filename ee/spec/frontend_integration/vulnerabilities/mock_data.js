export const mockVulnerability = {
  id: 1,
  title: 'Vulnerability Title',
  description: 'Vulnerability Description',
  created_at: new Date().toISOString(),
  severity: 'medium',
  state: 'detected',
  pipeline: {
    id: 2,
    created_at: new Date().toISOString(),
  },
  project: {
    full_path: '/project_full_path',
  },
};
