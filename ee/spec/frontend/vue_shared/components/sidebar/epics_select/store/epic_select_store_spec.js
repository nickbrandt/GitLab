import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

import EpicsSelectStore from 'ee/vue_shared/components/sidebar/epics_select/store/epics_select_store';

import { mockIssue, mockEpics } from '../../../../../sidebar/mock_data';

describe('EpicsSelect', () => {
  describe('Store', () => {
    const normalizedEpics = mockEpics.map(epic =>
      convertObjectPropsToCamelCase(Object.assign(epic, { url: epic.web_edit_url }), {
        dropKeys: ['web_edit_url'],
      }),
    );
    let store;

    beforeEach(() => {
      store = new EpicsSelectStore({
        groupId: normalizedEpics[0].groupId,
        selectedEpic: normalizedEpics[0],
        selectedEpicIssueId: mockIssue.epic_issue_id,
      });
    });

    describe('constructor', () => {
      it('should initialize `state` with all the required properties', () => {
        expect(store.groupId).toBe(normalizedEpics[0].groupId);
        expect(store.state).toEqual(
          expect.objectContaining({
            epics: [],
            allEpics: [],
            selectedEpic: normalizedEpics[0],
            selectedEpicIssueId: mockIssue.epic_issue_id,
          }),
        );
      });
    });

    describe('setEpics', () => {
      it('should set passed `rawEpics` into the store state by normalizing it', () => {
        store.setEpics(mockEpics);

        expect(store.state.epics.length).toBe(mockEpics.length);
        expect(store.state.allEpics.length).toBe(mockEpics.length);
        expect(store.state.epics[0]).toEqual(
          expect.objectContaining({
            ...normalizedEpics[0],
          }),
        );
        expect(store.state.allEpics[0]).toEqual(
          expect.objectContaining({
            ...normalizedEpics[0],
          }),
        );
      });
    });

    describe('getEpics', () => {
      it('should return value of `state.epics`', () => {
        store.setEpics(mockEpics);

        const epics = store.getEpics();

        expect(epics.length).toBe(mockEpics.length);
      });
    });

    describe('filterEpics', () => {
      beforeEach(() => {
        store.setEpics(mockEpics);
      });

      it('should return `state.epics` filtered Epic Title', () => {
        store.filterEpics('consequatur');

        const epics = store.getEpics();

        expect(epics.length).toBe(1);
        expect(epics[0]).toEqual(
          expect.objectContaining({
            ...normalizedEpics[0],
          }),
        );
      });

      it('should return `state.epics` filtered Epic Reference', () => {
        store.filterEpics('gitlab-org&1');

        const epics = store.getEpics();

        expect(epics.length).toBe(1);
        expect(epics[0]).toEqual(
          expect.objectContaining({
            ...normalizedEpics[0],
          }),
        );
      });

      it('should return `state.epics` filtered Epic URL', () => {
        store.filterEpics('http://gitlab.example.com/groups/gitlab-org/-/epics/2');

        const epics = store.getEpics();

        expect(epics.length).toBe(1);
        expect(epics[0]).toEqual(
          expect.objectContaining({
            ...normalizedEpics[1],
          }),
        );
      });

      it('should return `state.epics` filtered Epic Iid', () => {
        store.filterEpics('2');

        const epics = store.getEpics();

        expect(epics.length).toBe(1);
        expect(epics[0]).toEqual(
          expect.objectContaining({
            ...normalizedEpics[1],
          }),
        );
      });

      it('should return `state.epics` without any filters when query is empty', () => {
        store.filterEpics('');

        const epics = store.getEpics();

        expect(epics.length).toBe(normalizedEpics.length);
        epics.forEach((epic, index) => {
          expect.objectContaining({
            ...normalizedEpics[index],
          });
        });
      });
    });

    describe('setSelectedEpic', () => {
      it('should set provided `selectedEpic` param to store state', () => {
        store.setSelectedEpic(normalizedEpics[1]);

        expect(store.state.selectedEpic).toBe(normalizedEpics[1]);
      });
    });

    describe('setSelectedEpicIssueId', () => {
      it('should set provided `selectedEpicIssueId` param to store state', () => {
        store.setSelectedEpicIssueId(7);

        expect(store.state.selectedEpicIssueId).toBe(7);
      });
    });

    describe('getSelectedEpic', () => {
      it('should return value of `selectedEpic` from store state', () => {
        store.setSelectedEpic(normalizedEpics[1]);

        expect(store.getSelectedEpic()).toBe(normalizedEpics[1]);
      });
    });

    describe('getSelectedEpicIssueId', () => {
      it('should return value of `selectedEpicIssueId` from store state', () => {
        store.setSelectedEpicIssueId(7);

        expect(store.getSelectedEpicIssueId()).toBe(7);
      });
    });
  });
});
