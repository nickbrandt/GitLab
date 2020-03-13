import { shallowMount } from '@vue/test-utils';
import SidebarStatus from 'ee/sidebar/components/status/sidebar_status.vue';
import Status from 'ee/sidebar/components/status/status.vue';

describe('SidebarStatus', () => {
  const mediator = {
    store: {
      isFetching: {
        status: true,
      },
      status: '',
    },
  };

  const handleFormSubmissionMock = jest.fn();

  const wrapper = shallowMount(SidebarStatus, {
    propsData: {
      mediator,
    },
    methods: {
      handleFormSubmission: handleFormSubmissionMock,
    },
  });

  it('renders Status component', () => {
    expect(wrapper.contains(Status)).toBe(true);
  });

  it('calls handleFormSubmission when receiving an onFormSubmit event from Status component', () => {
    wrapper.find(Status).vm.$emit('onFormSubmit', 'onTrack');

    expect(handleFormSubmissionMock).toHaveBeenCalledWith('onTrack');
  });
});
