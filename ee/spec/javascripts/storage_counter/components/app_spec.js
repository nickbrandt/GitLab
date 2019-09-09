import { shallowMount } from '@vue/test-utils';
import StorageApp from 'ee/storage_counter/components/app.vue';
import Project from 'ee/storage_counter/components/project.vue';
import { projects, withRootStorageStatistics } from '../data';

describe('Storage counter app', () => {
  let wrapper;

  function createComponent(loading = false) {
    const $apollo = {
      queries: {
        namespace: {
          loading,
        },
      },
    };

    wrapper = shallowMount(StorageApp, {
      propsData: { namespacePath: 'h5bp', helpPagePath: 'help' },
      mocks: { $apollo },
      sync: true,
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the 2 projects', () => {
    wrapper.setData({
      namespace: projects,
    });

    expect(wrapper.findAll(Project).length).toEqual(2);
  });

  describe('with rootStorageStatistics information', () => {
    it('renders total usage', () => {
      wrapper.setData({
        namespace: withRootStorageStatistics,
      });

      expect(wrapper.find('.js-total-usage').text()).toContain(
        withRootStorageStatistics.totalUsage,
      );
    });
  });

  describe('without rootStorageStatistics information', () => {
    it('renders N/A', () => {
      wrapper.setData({
        namespace: projects,
      });

      expect(wrapper.find('.js-total-usage').text()).toContain('N/A');
    });
  });
});
