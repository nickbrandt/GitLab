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
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the 2 projects', done => {
    wrapper.setData({
      namespace: projects,
    });

    wrapper.vm
      .$nextTick()
      .then(() => {
        expect(wrapper.findAll(Project)).toHaveLength(2);
      })
      .then(done)
      .catch(done.fail);
  });

  describe('with rootStorageStatistics information', () => {
    it('renders total usage', done => {
      wrapper.setData({
        namespace: withRootStorageStatistics,
      });

      wrapper.vm
        .$nextTick()
        .then(() => {
          expect(wrapper.find("[data-testid='total-usage']").text()).toContain(
            withRootStorageStatistics.totalUsage,
          );
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('without rootStorageStatistics information', () => {
    it('renders N/A', done => {
      wrapper.setData({
        namespace: projects,
      });

      wrapper.vm
        .$nextTick()
        .then(() => {
          expect(wrapper.find("[data-testid='total-usage']").text()).toContain('N/A');
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
