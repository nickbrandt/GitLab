import getters from 'ee/boards/stores/getters';
import { mockIssue, mockIssue3, mockIssue4, mockIssues, mockIssuesByListId } from '../mock_data';

describe('EE Boards Store Getters', () => {
  const boardsState = {
    issuesByListId: mockIssuesByListId,
  };

  describe('getIssues', () => {
    it('returns issues for a given listId', () => {
      expect(getters.getIssues(boardsState)('gid://gitlab/List/2')).toEqual(mockIssues);
    });
  });

  describe('getIssuesByEpic', () => {
    it('returns issues for a given listId and epicId', () => {
      const getIssues = () => mockIssues;
      expect(
        getters.getIssuesByEpic(boardsState, { getIssues })(
          'gid://gitlab/List/2',
          'gid://gitlab/Epic/41',
        ),
      ).toEqual([mockIssue]);
    });
  });

  describe('unassignedIssues', () => {
    it('returns issues for a given listId and epicId', () => {
      const getIssues = () => [mockIssue, mockIssue3, mockIssue4];
      expect(getters.unassignedIssues(boardsState, { getIssues })('gid://gitlab/List/1')).toEqual([
        mockIssue3,
        mockIssue4,
      ]);
    });
  });
});
