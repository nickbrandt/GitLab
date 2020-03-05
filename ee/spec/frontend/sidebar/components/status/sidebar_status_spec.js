import { shallowMount } from '@vue/test-utils';
import SidebarStatus from 'ee/sidebar/components/status/sidebar_status.vue';
import Status from 'ee/sidebar/components/status/status.vue';

describe('SidebarStatus', () => {
  it('renders Status component', () => {
    const mediator = {
      store: {
        isFetching: {
          status: true,
        },
        status: '',
      },
    };

    const wrapper = shallowMount(SidebarStatus, {
      propsData: {
        mediator,
      },
    });

    expect(wrapper.contains(Status)).toBe(true);
  });
});
