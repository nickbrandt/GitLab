import { shallowMount, createLocalVue } from '@vue/test-utils';
import StorageApp from 'ee/storage_counter/components/app.vue';
import Project from 'ee/storage_counter/components/project.vue';
import { projects, withRootStorageStatistics } from '../data';

const localVue = createLocalVue();

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

    wrapper = shallowMount(localVue.extend(StorageApp), {
      propsData: { namespacePath: 'h5bp', helpPagePath: 'help' },
      mocks: { $apollo },
      sync: false,
      localVue,
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
        expect(wrapper.findAll(Project).length).toEqual(2);
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
          expect(wrapper.find('.js-total-usage').text()).toContain(
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
          expect(wrapper.find('.js-total-usage').text()).toContain('N/A');
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
