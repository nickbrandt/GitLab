import { createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { SET_BRANCH_WORKING_REFERENCE } from '~/ide/stores/mutation_types';
import { TEST_HOST } from 'spec/test_constants';
import terminalModule from 'ee/ide/stores/modules/terminal';
import extendStore from 'ee/ide/stores/extend';

const TEST_DATASET = {
  eeWebTerminalSvgPath: `${TEST_HOST}/web/terminal/svg`,
  eeWebTerminalHelpPath: `${TEST_HOST}/web/terminal/help`,
  eeWebTerminalConfigHelpPath: `${TEST_HOST}/web/terminal/config/help`,
  eeWebTerminalRunnersHelpPath: `${TEST_HOST}/web/terminal/runners/help`,
};
const localVue = createLocalVue();
localVue.use(Vuex);

describe('ee/ide/stores/extend', () => {
  let store;

  beforeEach(() => {
    const el = document.createElement('div');
    Object.assign(el.dataset, TEST_DATASET);

    store = new Vuex.Store({
      mutations: {
        [SET_BRANCH_WORKING_REFERENCE]: () => {},
      },
    });

    spyOn(store, 'registerModule');
    spyOn(store, 'dispatch');

    store = extendStore(store, el);
  });

  it('registers terminal module', () => {
    expect(store.registerModule).toHaveBeenCalledWith('terminal', terminalModule());
  });

  it('dispatches terminal/setPaths', () => {
    expect(store.dispatch).toHaveBeenCalledWith('terminal/setPaths', {
      webTerminalSvgPath: TEST_DATASET.eeWebTerminalSvgPath,
      webTerminalHelpPath: TEST_DATASET.eeWebTerminalHelpPath,
      webTerminalConfigHelpPath: TEST_DATASET.eeWebTerminalConfigHelpPath,
      webTerminalRunnersHelpPath: TEST_DATASET.eeWebTerminalRunnersHelpPath,
    });
  });

  it(`dispatches terminal/init on ${SET_BRANCH_WORKING_REFERENCE}`, () => {
    store.dispatch.calls.reset();

    store.commit(SET_BRANCH_WORKING_REFERENCE);

    expect(store.dispatch).toHaveBeenCalledWith('terminal/init');
  });
});
