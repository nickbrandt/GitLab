import ListIssue from '~/boards/models/issue';
import IssueProject from '~/boards/models/project';

class ListIssueEE extends ListIssue {
  constructor(obj) {
    super(obj, {
      IssueProject,
    });

    this.weight = obj.weight;

    if (obj.project) {
      this.project = new IssueProject(obj.project);
    }
  }
}

window.ListIssue = ListIssueEE;

export default ListIssueEE;
