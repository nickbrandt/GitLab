import EEIde from 'ee/ide/components/ide.vue';
import extendStore from 'ee/ide/stores/extend';
import { startIde } from '~/ide/index';

startIde({
  extendStore,
  rootComponent: EEIde,
});
