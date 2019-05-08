import eventHub from '~/ide/eventhub';
import mirror from '../../lib/mirror';

export default function createMirrorPlugin() {
  return store => {
    eventHub.$on('editor.save', () => mirror.upload(store.state));
  };
}
