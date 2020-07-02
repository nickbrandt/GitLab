import filterByKey from '~/reports/codequality_report/store/utils/filter_by_key';
import { mockParsedHeadIssues, mockParsedBaseIssues, issueDiff } from '../../mock_data';

describe('filterByKey', () => {
  it('should return a diff of the arrays based on the given key', () => {
    const result = filterByKey(mockParsedHeadIssues, mockParsedBaseIssues, 'fingerprint');

    expect(result).toEqual(issueDiff);
  });
});
