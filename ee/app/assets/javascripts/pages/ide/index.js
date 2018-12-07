import { startIde } from '~/ide/index';
import EEIde from 'ee/ide/components/ide.vue';
import extendStore from 'ee/ide/stores/extend';

startIde({
  extendStore,
  rootComponent: EEIde,
});
