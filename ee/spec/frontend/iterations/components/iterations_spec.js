import Iterations from 'ee/iterations/components/iterations.vue';
import IterationsList from 'ee/iterations/components/iterations_list.vue';
import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon, GlTab, GlTabs } from '@gitlab/ui';

describe('Iterations tabs', () => {
  let wrapper;
  const defaultProps = {
    groupPath: 'gitlab-org',
  };

  const mountComponent = ({ props = defaultProps, loading = false } = {}) => {
    wrapper = shallowMount(Iterations, {
      propsData: props,
      mocks: {
        $apollo: {
          queries: { iterations: { loading } },
        },
      },
      stubs: {
        GlLoadingIcon,
        GlTab,
        GlTabs,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('hides list while loading', () => {
    mountComponent({
      loading: true,
    });

    expect(wrapper.find(GlLoadingIcon).exists()).toBeTruthy();
    expect(wrapper.find(IterationsList).exists()).toBeFalsy();
  });

  it('shows iterations list when not loading', () => {
    mountComponent({
      loading: false,
    });

    expect(wrapper.find(GlLoadingIcon).exists()).toBeFalsy();
    expect(wrapper.find(IterationsList).exists()).toBeTruthy();
  });

  it('sets computed state from tabIndex', () => {
    mountComponent();

    expect(wrapper.vm.state).toEqual('opened');

    wrapper.vm.tabIndex = 1;

    expect(wrapper.vm.state).toEqual('closed');

    wrapper.vm.tabIndex = 2;

    expect(wrapper.vm.state).toEqual('all');
  });
});
