import { transformIssuesApiEndpoint } from 'ee/issues_analytics/utils';
import { TEST_HOST } from 'helpers/test_constants';

const dirtyEndpoint = `${TEST_HOST}/issues?label_name[]=cool&label_name[]=beans&milestone_title=v4.0`;
const cleanEndpoint = `${TEST_HOST}/issues?labels=cool%2Cbeans&milestone=v4.0`;

describe('issues analytics utils', () => {
  describe('transformIssuesApiEndpoint', () => {
    it('replaces the params as expected', () => {
      const endpoint = transformIssuesApiEndpoint(dirtyEndpoint);

      expect(endpoint).toBe(cleanEndpoint);
    });
  });
});
