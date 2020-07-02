import {
  parseCodeclimateMetrics,
  doCodeClimateComparison,
} from '~/reports/codequality_report/store/utils/codequality_comparison';
import mockFilterByKey from '~/reports/codequality_report/store/utils/filter_by_key';
import { baseIssues, mockParsedHeadIssues, mockParsedBaseIssues } from '../../mock_data';

jest.mock('~/reports/codequality_report/workers/codequality_comparison_worker', () => {
  let mockPostMessageCallback;
  return jest.fn().mockImplementation(() => {
    return {
      addEventListener: (_, callback) => {
        mockPostMessageCallback = callback;
      },
      postMessage: data => {
        if (!data.headIssues) return mockPostMessageCallback({ data: {} });
        if (!data.baseIssues) throw new Error();
        return mockPostMessageCallback({
          data: {
            newIssues: mockFilterByKey(data.headIssues, data.baseIssues, 'fingerprint'),
            resolvedIssues: mockFilterByKey(data.baseIssues, data.headIssues, 'fingerprint'),
          },
        });
      },
    };
  });
});

describe('Codequality report store utils', () => {
  let result;

  describe('parseCodeclimateMetrics', () => {
    it('should parse the received issues', () => {
      [result] = parseCodeclimateMetrics(baseIssues, 'path');

      expect(result.name).toEqual(baseIssues[0].check_name);
      expect(result.path).toEqual(baseIssues[0].location.path);
      expect(result.line).toEqual(baseIssues[0].location.lines.begin);
    });
  });

  describe('doCodeClimateComparison', () => {
    describe('when the comparison worker finds changed issues', () => {
      beforeEach(async () => {
        result = await doCodeClimateComparison(mockParsedHeadIssues, mockParsedBaseIssues);
      });

      it('returns the new and resolved issues', () => {
        expect(result.resolvedIssues[0]).toEqual(mockParsedBaseIssues[0]);
        expect(result.newIssues[0]).toEqual(mockParsedHeadIssues[0]);
      });
    });

    describe('when the comparison worker finds no changed issues', () => {
      beforeEach(async () => {
        result = await doCodeClimateComparison([], []);
      });

      it('returns the empty issue arrays', () => {
        expect(result.newIssues).toEqual([]);
        expect(result.resolvedIssues).toEqual([]);
      });
    });

    describe('when the comparison worker is given malformed data', () => {
      it('rejects the promise', () => {
        return expect(doCodeClimateComparison(null)).rejects.toEqual({});
      });
    });

    describe('when the comparison worker encounters an error', () => {
      it('rejects the promise and throws an error', () => {
        return expect(doCodeClimateComparison([], null)).rejects.toThrow();
      });
    });
  });
});
