import { mockIssueLink } from './mock_data';

export const createIssueLinksRoute = () => {
  mockServer.get('/api/v4/vulnerabilities/:id/issue_links', () => [mockIssueLink]);
};
