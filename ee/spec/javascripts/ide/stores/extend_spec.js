import { createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { SET_BRANCH_WORKING_REFERENCE } from '~/ide/stores/mutation_types';
import { TEST_HOST } from 'spec/test_constants';
import terminalModule from 'ee/ide/stores/modules/terminal';
import extendStore from 'ee/ide/stores/extend';

const TEST_DATASET = {
  eeCiYamlHelpPath: `${TEST_HOST}/ci/yaml/help`,
  eeCiRunnersHelpPath: `${TEST_HOST}/ci/runners/help`,
  eeWebTerminalHelpPath: `${TEST_HOST}/web/terminal/help`,
  eeWebTerminalSvgPath: `${TEST_HOST}/web/terminal/svg`,
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
      ciYamlHelpPath: TEST_DATASET.eeCiYamlHelpPath,
      ciRunnersHelpPath: TEST_DATASET.eeCiRunnersHelpPath,
      webTerminalHelpPath: TEST_DATASET.eeWebTerminalHelpPath,
      webTerminalSvgPath: TEST_DATASET.eeWebTerminalSvgPath,
    });
  });

  it(`dispatches terminal/init on ${SET_BRANCH_WORKING_REFERENCE}`, () => {
    store.dispatch.calls.reset();

    store.commit(SET_BRANCH_WORKING_REFERENCE);

    expect(store.dispatch).toHaveBeenCalledWith('terminal/init');
  });
});
