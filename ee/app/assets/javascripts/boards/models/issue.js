import ListIssue from '~/boards/models/issue';
import IssueProject from '~/boards/models/project';

class ListIssueEE extends ListIssue {
  constructor(obj, defaultAvatar) {
    super(obj, defaultAvatar, {
      IssueProject,
    });

    this.isFetching.weight = true;
    this.isLoading.weight = false;
    this.weight = obj.weight;

    if (obj.project) {
      this.project = new IssueProject(obj.project);
    }
  }
}

window.ListIssue = ListIssueEE;

export default ListIssueEE;
