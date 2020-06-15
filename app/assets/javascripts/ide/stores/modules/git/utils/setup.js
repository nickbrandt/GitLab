import { debounce } from 'lodash';
import { FS_ROOT_PATH } from '../../../../constants';

// eslint-disable-next-line import/prefer-default-export
export const setupGitWatcher = store => {
  store.watch(
    state => state.fileSystem.files[FS_ROOT_PATH].timestamp,
    // WARNING: debouncing is probably not the right thing to do here. We should probably debounce the editor.
    debounce(timestamp => {
      store.dispatch('git/updateObjects', timestamp);
    }, 300),
  );

  store.watch(
    state => state.git.refs,
    val => {
      console.log(JSON.parse(JSON.stringify(val)));
      console.log(Object.keys(store.state.git.objects).length);

      // WARNING: this kind of creates a race condition and is a bit of an expensive operation. We should think of a way to
      // assure async reliability + optimize for performance.
      store.dispatch('git/cleanObjects');

      console.log(Object.keys(store.state.git.objects).length);
    },
    { deep: true },
  );
};
