import { convertObjectPropsToCamelCase, searchBy } from '~/lib/utils/common_utils';

export default class EpicsSelectStore {
  constructor({ groupId, selectedEpic, selectedEpicIssueId }) {
    this.groupId = groupId;

    this.state = {};
    this.state.epics = [];
    this.state.allEpics = [];

    this.state.selectedEpic = selectedEpic;
    this.state.selectedEpicIssueId = selectedEpicIssueId;
  }

  setEpics(rawEpics) {
    // Cache all Epics so that
    // during search, we only work with `state.epics`
    this.state.allEpics = rawEpics
      .filter(epic => epic.group_id === this.groupId)
      .map(epic =>
        convertObjectPropsToCamelCase(Object.assign(epic, { url: epic.web_edit_url }), {
          dropKeys: ['web_edit_url'],
        }),
      );

    this.state.epics = this.state.allEpics;
  }

  getEpics() {
    return this.state.epics;
  }

  filterEpics(query) {
    if (query) {
      this.state.epics = this.state.allEpics.filter(epic => {
        const { title, reference, url, iid } = epic;

        // In case user has just pasted ID
        // We need to be specific with the search
        if (Number(query)) {
          return query.includes(iid);
        }

        return searchBy(query, {
          title,
          reference,
          url,
        });
      });
    } else {
      this.state.epics = this.state.allEpics;
    }
  }

  setSelectedEpic(selectedEpic) {
    this.state.selectedEpic = selectedEpic;
  }

  setSelectedEpicIssueId(selectedEpicIssueId) {
    this.state.selectedEpicIssueId = selectedEpicIssueId;
  }

  getSelectedEpic() {
    return this.state.selectedEpic;
  }

  getSelectedEpicIssueId() {
    return this.state.selectedEpicIssueId;
  }
}
