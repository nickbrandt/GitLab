import { mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import SidebarStatus from 'ee/sidebar/components/status/sidebar_status.vue';
import Status from 'ee/sidebar/components/status/status.vue';

const getStatusText = wrapper => wrapper.find('.value').text();

describe('SidebarStatus', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('Status child component', () => {
    let handleFormSubmissionMock;

    beforeEach(() => {
      const mediator = {
        store: {
          isFetching: {
            status: true,
          },
          status: '',
        },
      };

      handleFormSubmissionMock = jest.fn();

      wrapper = shallowMount(SidebarStatus, {
        propsData: {
          mediator,
        },
        methods: {
          handleFormSubmission: handleFormSubmissionMock,
        },
      });
    });

    it('renders Status component', () => {
      expect(wrapper.contains(Status)).toBe(true);
    });

    it('calls handleFormSubmission when receiving an onStatusChange event from Status component', () => {
      wrapper.find(Status).vm.$emit('onStatusChange', 'onTrack');

      expect(handleFormSubmissionMock).toHaveBeenCalledWith('onTrack');
    });
  });

  it('removes status when user clicks on "remove status"', () => {
    const mediator = {
      store: {
        editable: true,
        isFetching: {
          status: false,
        },
        status: 'onTrack',
      },
      updateStatus(status) {
        this.store.status = status;
        wrapper.setProps({
          mediator: {
            ...this,
          },
        });
        return Promise.resolve();
      },
    };

    wrapper = mount(SidebarStatus, {
      propsData: {
        mediator,
      },
    });

    expect(getStatusText(wrapper)).toContain('On track');

    wrapper.find('button.btn-link').trigger('click');

    return Vue.nextTick().then(() => {
      expect(getStatusText(wrapper)).toBe('None');
    });
  });
});
