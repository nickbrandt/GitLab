import { debounce } from 'lodash';
import { FS_ROOT_PATH } from '../../../../constants';

// eslint-disable-next-line import/prefer-default-export
export const setupGitWatcher = store => {
  store.watch(
    state => state.fileSystem.files[FS_ROOT_PATH].timestamp,
    // WARNING: debouncing is probably not the right thing to do here. We should probably debounce the editor.
    debounce(timestamp => {
      store.dispatch('git/updateObjects', timestamp);
    }, 500),
  );

  store.watch(
    state => state.git.refs,
    val => {
      console.log('[ide.git] refs', JSON.parse(JSON.stringify(val)));
      store.dispatch('git/refreshStatus');

      // WARNING: this kind of creates a race condition and is a bit of an expensive operation. We should think of a way to
      // assure async reliability + optimize for performance.
      console.log(
        '[ide.git] pre clean object count - ',
        Object.keys(store.state.git.objects).length,
      );

      store.dispatch('git/cleanObjects');

      console.log(
        '[ide.git] post clean object count - ',
        Object.keys(store.state.git.objects).length,
      );
    },
    { deep: true },
  );

  store.watch(
    state => state.git.status,
    val => {
      console.log('[ide.git] status - ', JSON.parse(JSON.stringify(val)));
    },
    { deep: true },
  );

  window.store = store;
};
