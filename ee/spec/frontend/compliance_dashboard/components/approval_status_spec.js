import { shallowMount } from '@vue/test-utils';

import ApprovalStatus from 'ee/compliance_dashboard/components/approval_status.vue';

describe('ApprovalStatus component', () => {
  let wrapper;

  const findIcon = () => wrapper.find('.ci-icon');
  const findLink = () => wrapper.find('a');

  const createComponent = status => {
    return shallowMount(ApprovalStatus, {
      propsData: { status },
      stubs: {
        CiIcon: {
          props: { status: Object },
          template: `<div class="ci-icon">{{ status.icon }}</div>`,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with an approval status', () => {
    const approvalStatus = 'success';

    beforeEach(() => {
      wrapper = createComponent(approvalStatus);
    });

    it('links to the approval status', () => {
      expect(findLink().attributes('href')).toEqual(
        'https://docs.gitlab.com/ee/user/compliance/compliance_dashboard/#approval-status-and-separation-of-duties',
      );
    });

    it('renders an icon with the approval status', () => {
      expect(findIcon().text()).toEqual(`status_${approvalStatus}`);
    });

    it.each`
      status       | tooltip
      ${'success'} | ${'Adheres to separation of duties'}
      ${'warning'} | ${'At least one rule does not adhere to separation of duties'}
      ${'failed'}  | ${'Fails to adhere to separation of duties'}
    `('shows the correct tooltip for $status', ({ status, tooltip }) => {
      wrapper = createComponent(status);

      expect(wrapper.vm.tooltip).toEqual(tooltip);
    });
  });

  describe('with a warning approval status', () => {
    const approvalStatus = 'warning';

    beforeEach(() => {
      wrapper = createComponent(approvalStatus);
    });

    it('returns the correct status object`', () => {
      expect(wrapper.vm.iconStatus).toEqual({
        group: 'success-with-warnings',
        icon: 'status_warning',
      });
    });
  });
});
