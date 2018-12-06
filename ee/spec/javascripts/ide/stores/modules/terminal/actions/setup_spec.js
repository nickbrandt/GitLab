import testAction from 'spec/helpers/vuex_action_helper';
import * as mutationTypes from 'ee/ide/stores/modules/terminal/mutation_types';
import * as actions from 'ee/ide/stores/modules/terminal/actions/setup';

describe('EE IDE store terminal setup actions', () => {
  describe('hideSplash', () => {
    it('commits HIDE_SPLASH', done => {
      testAction(actions.hideSplash, null, {}, [{ type: mutationTypes.HIDE_SPLASH }], [], done);
    });
  });

  describe('setPaths', () => {
    it('commits SET_PATHS', done => {
      const paths = {
        foo: 'bar',
        lorem: 'ipsum',
      };

      testAction(
        actions.setPaths,
        paths,
        {},
        [{ type: mutationTypes.SET_PATHS, payload: paths }],
        [],
        done,
      );
    });
  });
});
