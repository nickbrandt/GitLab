import * as getters from 'ee/vue_shared/components/sidebar/epics_select/store/getters';

import createDefaultState from 'ee/vue_shared/components/sidebar/epics_select/store/state';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

import { mockEpics } from '../../mock_data';

describe('EpicsSelect', () => {
  describe('store', () => {
    describe('getters', () => {
      let state;
      const normalizedEpics = mockEpics.map(rawEpic =>
        convertObjectPropsToCamelCase(Object.assign(rawEpic, { url: rawEpic.web_edit_url }), {
          dropKeys: ['web_edit_url'],
        }),
      );

      beforeEach(() => {
        state = createDefaultState();
        state.epics = normalizedEpics;
      });

      describe('groupEpics', () => {
        it('should return `state.epics` without any filters when `state.searchQuery` is empty', () => {
          state.searchQuery = '';

          const epics = getters.groupEpics(state);

          expect(epics.length).toBe(normalizedEpics.length);
          epics.forEach((epic, index) => {
            expect.objectContaining({
              ...normalizedEpics[index],
            });
          });
        });

        it('should return `state.epics` filtered by Epic Title', () => {
          state.searchQuery = 'consequatur';

          const epics = getters.groupEpics(state);

          expect(epics.length).toBe(1);
          expect(epics[0]).toEqual(
            expect.objectContaining({
              ...normalizedEpics[0],
            }),
          );
        });

        it('should return `state.epics` filtered by Epic Reference', () => {
          state.searchQuery = 'gitlab-org&1';

          const epics = getters.groupEpics(state);

          expect(epics.length).toBe(1);
          expect(epics[0]).toEqual(
            expect.objectContaining({
              ...normalizedEpics[0],
            }),
          );
        });

        it('should return `state.epics` filtered Epic URL', () => {
          state.searchQuery = 'http://gitlab.example.com/groups/gitlab-org/-/epics/2';

          const epics = getters.groupEpics(state);

          expect(epics.length).toBe(1);
          expect(epics[0]).toEqual(
            expect.objectContaining({
              ...normalizedEpics[1],
            }),
          );
        });

        it('should return `state.epics` filtered by Epic Iid', () => {
          state.searchQuery = '2';

          const epics = getters.groupEpics(state);

          expect(epics.length).toBe(1);
          expect(epics[0]).toEqual(
            expect.objectContaining({
              ...normalizedEpics[1],
            }),
          );
        });
      });
    });
  });
});
