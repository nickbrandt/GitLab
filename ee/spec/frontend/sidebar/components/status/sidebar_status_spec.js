import { shallowMount } from '@vue/test-utils';
import SidebarStatus from 'ee/sidebar/components/status/sidebar_status.vue';
import Status from 'ee/sidebar/components/status/status.vue';

describe('SidebarStatus', () => {
  let wrapper;
  let handleDropdownClickMock;

  beforeEach(() => {
    const mediator = {
      store: {
        isFetching: {
          status: true,
        },
        status: '',
      },
    };

    handleDropdownClickMock = jest.fn();

    wrapper = shallowMount(SidebarStatus, {
      propsData: {
        mediator,
      },
      methods: {
        handleDropdownClick: handleDropdownClickMock,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('Status child component', () => {
    beforeEach(() => {});

    it('renders Status component', () => {
      expect(wrapper.contains(Status)).toBe(true);
    });

    it('calls handleFormSubmission when receiving an onDropdownClick event from Status component', () => {
      wrapper.find(Status).vm.$emit('onDropdownClick', 'onTrack');

      expect(handleDropdownClickMock).toHaveBeenCalledWith('onTrack');
    });
  });

  it('calls handleFormSubmission when receiving an onFormSubmit event from Status component', () => {
    wrapper.find(Status).vm.$emit('onDropdownClick', 'onTrack');

    expect(handleDropdownClickMock).toHaveBeenCalledWith('onTrack');
  });
});
