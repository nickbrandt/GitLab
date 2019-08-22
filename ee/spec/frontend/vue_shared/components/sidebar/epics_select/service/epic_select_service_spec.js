import Api from 'ee/api';

import EpicsSelectService from 'ee/vue_shared/components/sidebar/epics_select/service/epics_select_service';

import {
  mockEpic1,
  mockIssue,
  mockEpics,
  mockAssignRemoveRes,
} from '../../../../../sidebar/mock_data';

describe('EpicsSelect', () => {
  describe('Service', () => {
    const service = new EpicsSelectService({ groupId: mockEpic1.group_id });

    describe('getGroupEpics', () => {
      it('calls `Api.groupEpics` with `groupId`', () => {
        jest.spyOn(Api, 'groupEpics').mockResolvedValue({ data: mockEpics });

        service.getGroupEpics();

        expect(Api.groupEpics).toHaveBeenCalledWith(
          expect.objectContaining({
            groupId: mockEpic1.group_id,
          }),
        );
      });
    });

    describe('assignIssueToEpic', () => {
      it('calls `Api.addEpicIssue` with `issueId`, `groupId` & `epicIid`', () => {
        jest.spyOn(Api, 'addEpicIssue').mockResolvedValue({ data: mockAssignRemoveRes });

        service.assignIssueToEpic(mockIssue.id, {
          groupId: mockEpic1.group_id,
          iid: mockEpic1.iid,
        });

        expect(Api.addEpicIssue).toHaveBeenCalledWith(
          expect.objectContaining({
            issueId: mockIssue.id,
            groupId: mockEpic1.group_id,
            epicIid: mockEpic1.iid,
          }),
        );
      });
    });

    describe('removeIssueFromEpic', () => {
      it('calls `Api.removeEpicIssue` with `epicIssueId`, `groupId` & `epicIid`', () => {
        jest.spyOn(Api, 'removeEpicIssue').mockResolvedValue({ data: mockAssignRemoveRes });

        service.removeIssueFromEpic(mockIssue.epic_issue_id, {
          groupId: mockEpic1.group_id,
          iid: mockEpic1.iid,
        });

        expect(Api.removeEpicIssue).toHaveBeenCalledWith(
          expect.objectContaining({
            epicIssueId: mockIssue.epic_issue_id,
            groupId: mockEpic1.group_id,
            epicIid: mockEpic1.iid,
          }),
        );
      });
    });
  });
});
