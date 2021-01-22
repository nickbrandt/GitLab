import { GlTabs } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import GroupTabs from '~/pages/groups/new/group_tabs.vue';

describe('GroupTabs', () => {
  let wrapper;
  const spyClick = jest.fn();

  const createComponent = () => {
    wrapper = shallowMount(GroupTabs, {
      listeners: {
        click: spyClick,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('default', () => {
    beforeEach(() => createComponent());

    it('renders tabs', () => {
      expect(wrapper.findComponent(GlTabs).exists()).toBe(true);
    });

    // TODO fix
    // it('emits click event when clicked', async () => {
    //   wrapper.findComponent(GlTab).trigger('click');
    //   expect(spyClick).toHaveBeenCalled();
    // });
  });
});
