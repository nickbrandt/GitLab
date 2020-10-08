import Vuex from 'vuex';
import eventHub from '~/ide/eventhub';
import { createStoreOptions } from '~/ide/stores';
import { setupFileEditorsSync } from '~/ide/stores/modules/editor/setup';

describe('~/ide/stores/modules/editor/setup', () => {
  it('when files change is emitted, removes unused fileEditors', async () => {
    const store = new Vuex.Store(createStoreOptions());
    store.state.entries = {
      foo: {},
      bar: {},
    };
    store.state.editor.fileEditors = {
      foo: {},
      bizz: {},
    };

    setupFileEditorsSync(store);
    eventHub.$emit('ide.files.change');

    expect(store.state.entries).toEqual({
      foo: {},
      bar: {},
    });
    expect(store.state.editor.fileEditors).toEqual({
      foo: {},
    });
  });
});
