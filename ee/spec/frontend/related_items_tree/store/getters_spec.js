import * as getters from 'ee/related_items_tree/store/getters';

import createDefaultState from 'ee/related_items_tree/store/state';

import { issuableTypesMap } from 'ee/related_issues/constants';
import { ChildType } from 'ee/related_items_tree/constants';

import { mockEpic1, mockEpic2 } from '../../../javascripts/related_items_tree/mock_data';

window.gl = window.gl || {};

describe('RelatedItemsTree', () => {
  describe('store', () => {
    describe('getters', () => {
      const { GfmAutoComplete } = gl;
      let state;

      beforeAll(() => {
        gl.GfmAutoComplete = {
          dataSources: 'foo/bar',
        };
      });

      beforeEach(() => {
        state = createDefaultState();
      });

      afterAll(() => {
        gl.GfmAutoComplete = GfmAutoComplete;
      });

      describe('autoCompleteSources', () => {
        it('returns GfmAutoComplete.dataSources from global `gl` object', () => {
          expect(getters.autoCompleteSources()).toBe(gl.GfmAutoComplete.dataSources);
        });
      });

      describe('directChild', () => {
        it('returns array of children which belong to state.parentItem', () => {
          state.parentItem = mockEpic1;
          state.children[mockEpic1.reference] = [mockEpic2];

          expect(getters.directChildren(state)).toEqual(expect.arrayContaining([mockEpic2]));
        });
      });

      describe('anyParentHasChildren', () => {
        it('returns boolean representing whether any epic has children', () => {
          let mockGetter = {
            directChildren: [mockEpic1],
          };

          expect(getters.anyParentHasChildren(state, mockGetter)).toBe(true);

          mockGetter = {
            directChildren: [mockEpic2],
          };

          expect(getters.anyParentHasChildren(state, mockGetter)).toBe(false);
        });
      });

      describe('headerItems', () => {
        it('returns an item within array containing Epic iconName, count, qaClass & type props', () => {
          state.epicsCount = 2;
          const epicHeaderItem = getters.headerItems(state)[0];

          expect(epicHeaderItem).toEqual(
            expect.objectContaining({
              iconName: 'epic',
              count: 2,
              qaClass: 'qa-add-epics-button',
              type: ChildType.Epic,
            }),
          );
        });

        it('returns an item within array containing Issue iconName, count, qaClass & type props', () => {
          state.issuesCount = 2;
          const epicHeaderItem = getters.headerItems(state)[1];

          expect(epicHeaderItem).toEqual(
            expect.objectContaining({
              iconName: 'issues',
              count: 2,
              qaClass: 'qa-add-issues-button',
              type: ChildType.Issue,
            }),
          );
        });
      });

      describe('itemAutoCompleteSources', () => {
        it('returns autoCompleteSources value when `issuableType` is set to `Epic` and `autoCompleteEpics` is true', () => {
          const mockGetter = {
            autoCompleteSources: 'foo',
            isEpic: true,
          };
          state.issuableType = issuableTypesMap.Epic;
          state.autoCompleteEpics = true;

          expect(getters.itemAutoCompleteSources(state, mockGetter)).toBe('foo');

          state.autoCompleteEpics = false;

          expect(getters.itemAutoCompleteSources(state, mockGetter)).toEqual(
            expect.objectContaining({}),
          );
        });

        it('returns autoCompleteSources value when `issuableType` is set to `Issue` and `autoCompleteIssues` is true', () => {
          const mockGetter = {
            autoCompleteSources: 'foo',
          };
          state.issuableType = issuableTypesMap.Issue;
          state.autoCompleteIssues = true;

          expect(getters.itemAutoCompleteSources(state, mockGetter)).toBe('foo');

          state.autoCompleteIssues = false;

          expect(getters.itemAutoCompleteSources(state, mockGetter)).toEqual(
            expect.objectContaining({}),
          );
        });
      });

      describe('itemPathIdSeparator', () => {
        it('returns string containing pathIdSeparator for `Epic`  when isEpic is truee', () => {
          expect(getters.itemPathIdSeparator({}, { isEpic: true })).toBe('&');
        });

        it('returns string containing pathIdSeparator for `Issue` when isEpic is false', () => {
          expect(getters.itemPathIdSeparator({}, { isEpic: false })).toBe('#');
        });
      });

      describe('isEpic', () => {
        it.each`
          issuableType              | expectedValue
          ${null}                   | ${false}
          ${issuableTypesMap.ISSUE} | ${false}
          ${issuableTypesMap.EPIC}  | ${true}
        `(
          'for issuableType = issuableType is $expectedValue',
          ({ issuableType, expectedValue }) => {
            expect(getters.isEpic({ issuableType })).toBe(expectedValue);
          },
        );
      });
    });
  });
});
