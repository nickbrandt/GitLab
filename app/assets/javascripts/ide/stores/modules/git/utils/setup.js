import { FS_ROOT_PATH } from '../../../../constants';

// eslint-disable-next-line import/prefer-default-export
export const setupGitWatcher = store => {
  console.log('[ide.git] setupGitWatcher...');

  store.watch(
    state => state.fileSystem.files[FS_ROOT_PATH].timestamp,
    timestamp => {
      console.log(timestamp);
      store.dispatch('git/updateObjects', timestamp);
    },
  );

  store.watch(
    state => state.git.refs,
    val => {
      console.log(JSON.parse(JSON.stringify(val)));
      console.log(store.state.git.objects);
    },
    { deep: true },
  );
};
