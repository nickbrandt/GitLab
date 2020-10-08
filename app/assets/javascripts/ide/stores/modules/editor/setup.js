import eventHub from '~/ide/eventhub';

const removeUnusedFileEditors = store => {
  Object.keys(store.state.editor.fileEditors)
    .filter(path => !store.state.entries[path])
    .forEach(path => store.dispatch('editor/removeFileEditor', path));
};

export const setupFileEditorsSync = store => {
  eventHub.$on('ide.files.change', () => {
    removeUnusedFileEditors(store);
  });
};
