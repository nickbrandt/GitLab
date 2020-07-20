import IterationReport from 'ee/iterations/components/iteration_report.vue';
import { shallowMount } from '@vue/test-utils';
import { GlEmptyState, GlLoadingIcon, GlTab, GlTabs } from '@gitlab/ui';

describe('Iterations tabs', () => {
  let wrapper;
  const defaultProps = {
    groupPath: 'gitlab-org',
    iterationIid: '3',
  };

  const findTopbar = () => wrapper.find({ ref: 'topbar' });
  const findTitle = () => wrapper.find({ ref: 'title' });
  const findDescription = () => wrapper.find({ ref: 'description' });

  const mountComponent = ({ props = defaultProps, loading = false } = {}) => {
    wrapper = shallowMount(IterationReport, {
      propsData: props,
      mocks: {
        $apollo: {
          queries: { group: { loading } },
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

  it('shows spinner while loading', () => {
    mountComponent({
      loading: true,
    });

    expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
  });

  describe('empty state', () => {
    it('shows empty state if no item loaded', () => {
      mountComponent({
        loading: false,
      });

      expect(wrapper.find(GlEmptyState).exists()).toBe(true);
      expect(wrapper.find(GlEmptyState).props('title')).toEqual('Could not find iteration');
      expect(findTitle().exists()).toBe(false);
      expect(findDescription().exists()).toBe(false);
    });
  });

  describe('item loaded', () => {
    const iteration = {
      title: 'June week 1',
      id: 'gid://gitlab/Iteration/2',
      description: 'The first week of June',
      startDate: '2020-06-02',
      dueDate: '2020-06-08',
    };

    beforeEach(() => {
      mountComponent({
        loading: false,
      });

      wrapper.setData({
        group: {
          iteration,
        },
      });
    });

    it('shows status and date in header', () => {
      expect(findTopbar().text()).toContain('Open');
      expect(findTopbar().text()).toContain('Jun 2, 2020');
      expect(findTopbar().text()).toContain('Jun 8, 2020');
    });

    it('hides empty region and loading spinner', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
      expect(wrapper.find(GlEmptyState).exists()).toBe(false);
    });

    it('shows title and description', () => {
      expect(findTitle().text()).toContain(iteration.title);
      expect(findDescription().text()).toContain(iteration.description);
    });

    it('escapes html in description', async () => {
      wrapper.setData({
        group: {
          iteration: {
            ...iteration,
            description: `<img src=x onerror=alert(document.domain)>`,
          },
        },
      });

      await wrapper.vm.$nextTick();

      expect(findDescription().html()).toEqual(
        '<div>&lt;img src=x onerror=alert(document.domain)&gt;</div>',
      );
    });
  });
});
