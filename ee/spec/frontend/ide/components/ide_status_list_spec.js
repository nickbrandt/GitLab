import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import TerminalSyncStatusSafe from 'ee/ide/components/terminal_sync/terminal_sync_status_safe.vue';
import IdeStatusList from 'ee/ide/components/ide_status_list.vue';
import { createStore } from '~/ide/stores';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ee/ide/components/ide_status_list', () => {
  let store;
  let wrapper;

  const createComponent = () => {
    store = createStore();

    wrapper = mount(IdeStatusList, {
      localVue,
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders terminal sync status', () => {
    createComponent();

    expect(wrapper.find(TerminalSyncStatusSafe).exists()).toBe(true);
  });
});
