import * as mutationTypes from '~/ide/stores/mutation_types';
import terminalModule from './modules/terminal';

function getPathsFromData(el) {
  return {
    ciYamlHelpPath: el.dataset.eeCiYamlHelpPath,
    ciRunnersHelpPath: el.dataset.eeCiRunnersHelpPath,
    webTerminalHelpPath: el.dataset.eeWebTerminalHelpPath,
    webTerminalSvgPath: el.dataset.eeWebTerminalSvgPath,
  };
}

export default (store, el) => {
  store.registerModule('terminal', terminalModule());

  store.dispatch('terminal/setPaths', getPathsFromData(el));

  store.subscribe(({ type }) => {
    if (type === mutationTypes.SET_BRANCH_WORKING_REFERENCE) {
      store.dispatch('terminal/init');
    }
  });

  return store;
};
