import eventHub from '~/ide/eventhub';
import { createStore } from '~/ide/stores';
import createMirrorPlugin from 'ee/ide/stores/plugins/mirror';
import mirror from 'ee/ide/lib/mirror';

jest.mock('ee/ide/lib/mirror');

describe('EE IDE stores/plugins/mirror', () => {
  let store;
  let plugin;

  beforeEach(() => {
    store = createStore();
    plugin = createMirrorPlugin();

    plugin(store);
  });

  it('does not initally call upload', () => {
    expect(mirror.upload).not.toHaveBeenCalled();
  });

  it('uploads on editor.save event', () => {
    eventHub.$emit('editor.save');

    expect(mirror.upload).toHaveBeenCalledWith(store.state);
  });
});
