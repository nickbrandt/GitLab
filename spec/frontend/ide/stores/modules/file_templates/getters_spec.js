import createState from '~/ide/stores/state';
import createPaneState from '~/ide/stores/modules/pane/state';
import { leftSidebarViews } from '~/ide/constants';
import * as getters from '~/ide/stores/modules/file_templates/getters';

describe('IDE file templates getters', () => {
  describe('templateTypes', () => {
    it('returns list of template types', () => {
      expect(getters.templateTypes().length).toBe(4);
    });
  });

  describe('showFileTemplatesBar', () => {
    let rootState;

    beforeEach(() => {
      rootState = createState();
      const paneState = createPaneState();
      rootState.leftPane = paneState;
    });

    it('returns true if template is found and leftPane.currentView is edit', () => {
      rootState.leftPane.currentView = leftSidebarViews.ideTree.name;

      expect(
        getters.showFileTemplatesBar(
          null,
          {
            templateTypes: getters.templateTypes(),
          },
          rootState,
        )('LICENSE'),
      ).toBe(true);
    });

    it('returns false if template is found and leftPane.currentView is not edit', () => {
      rootState.leftPane.currentView = leftSidebarViews.commit.name;

      expect(
        getters.showFileTemplatesBar(
          null,
          {
            templateTypes: getters.templateTypes(),
          },
          rootState,
        )('LICENSE'),
      ).toBe(false);
    });

    it('returns undefined if not found', () => {
      expect(
        getters.showFileTemplatesBar(
          null,
          {
            templateTypes: getters.templateTypes(),
          },
          rootState,
        )('test'),
      ).toBe(undefined);
    });
  });
});
