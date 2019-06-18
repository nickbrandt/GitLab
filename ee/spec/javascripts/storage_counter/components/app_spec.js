import { shallowMount } from '@vue/test-utils';
import StorageApp from 'ee/storage_counter/components/app.vue';
import Project from 'ee/storage_counter/components/project.vue';
import { projects } from '../data';

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
      propsData: { namespacePath: 'h5bp' },
      mocks: { $apollo },
    });
  }

  beforeEach(() => {
    createComponent();
    wrapper.setData({
      namespace: projects,
    });
  });

  it('renders the 2 projects', () => {
    expect(wrapper.findAll(Project).length).toEqual(2);
  });
});
