import { GlTabs } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import GroupTabs from '~/pages/groups/new/group_tabs.vue';

describe('GroupTabs', () => {
  let wrapper;

  const createComponent = (theme = undefined) => {
    wrapper = shallowMount(GroupTabs, { propsData: { theme } });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('default', () => {
    it('renders tabs with default theme', () => {
      const theme = 'indigo';
      createComponent();
      expect(wrapper.findComponent(GlTabs).exists()).toBe(true);
      expect(wrapper.findComponent(GlTabs).props('theme')).toBe(theme);
    });

    it('renders tabs with chosen theme', () => {
      const theme = 'blue';
      createComponent(theme);
      expect(wrapper.findComponent(GlTabs).exists()).toBe(true);
      expect(wrapper.findComponent(GlTabs).props('theme')).toBe(theme);
    });
  });
});
