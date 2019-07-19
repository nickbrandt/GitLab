import Api from 'ee/api';

export default class EpicsSelectService {
  constructor({ groupId }) {
    this.groupId = groupId;
  }

  getGroupEpics() {
    return Api.groupEpics({
      groupId: this.groupId,
    });
  }

  // eslint-disable-next-line class-methods-use-this
  assignIssueToEpic(issueId, epic) {
    return Api.addEpicIssue({
      issueId,
      groupId: epic.groupId,
      epicIid: epic.iid,
    });
  }

  // eslint-disable-next-line class-methods-use-this
  removeIssueFromEpic(epicIssueId, epic) {
    return Api.removeEpicIssue({
      epicIssueId,
      groupId: epic.groupId,
      epicIid: epic.iid,
    });
  }
}
