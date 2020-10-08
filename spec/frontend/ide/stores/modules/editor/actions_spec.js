import testAction from 'helpers/vuex_action_helper';
import * as types from '~/ide/stores/modules/editor/mutation_types';
import * as actions from '~/ide/stores/modules/editor/actions';

describe('~/ide/stores/modules/editor/actions', () => {
  describe('updateFileEditor', () => {
    it('commits with payload', () => {
      const payload = {};

      testAction(actions.updateFileEditor, payload, {}, [
        { type: types.UPDATE_FILE_EDITOR, payload },
      ]);
    });
  });

  describe('removeFileEditor', () => {
    it('commits with payload', () => {
      const payload = 'path/to/file.txt';

      testAction(actions.removeFileEditor, payload, {}, [
        { type: types.REMOVE_FILE_EDITOR, payload },
      ]);
    });
  });
});
