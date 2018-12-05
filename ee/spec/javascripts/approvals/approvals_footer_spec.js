import Vue from 'vue';
import ApprovalsFooter from 'ee/vue_merge_request_widget/components/approvals/approvals_footer.vue';
import { TEST_HOST } from 'spec/test_constants';

describe('Approvals Footer Component', () => {
  let vm;
  const initialData = {
    mr: {
      state: 'readyToMerge',
    },
    service: {},
    userCanApprove: false,
    userHasApproved: true,
    approvedBy: [],
    approvalsLeft: 3,
  };

  beforeEach(() => {
    setFixtures('<div id="mock-container"></div>');
    const ApprovalsFooterComponent = Vue.extend(ApprovalsFooter);

    vm = new ApprovalsFooterComponent({
      el: '#mock-container',
      propsData: initialData,
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should correctly set component props', () => {
    Object.keys(vm).forEach(propKey => {
      if (initialData[propKey]) {
        expect(vm[propKey]).toBe(initialData[propKey]);
      }
    });
  });

  describe('Computed properties', () => {
    it('should correctly set showUnapproveButton when the user can unapprove', () => {
      expect(vm.showUnapproveButton).toBeTruthy();
      vm.mr.state = 'merged';

      expect(vm.showUnapproveButton).toBeFalsy();
    });

    it('should correctly set showUnapproveButton when the user can not unapprove', done => {
      vm.userCanApprove = true;

      Vue.nextTick(() => {
        expect(vm.showUnapproveButton).toBe(false);
        done();
      });
    });
  });

  describe('approvers list', () => {
    const avatarUrl = `${TEST_HOST}/dummy.jpg`;

    it('shows link to member avatar for for each approver', done => {
      vm.approvedBy = [
        {
          user: {
            username: 'Tanuki',
            avatar_url: avatarUrl,
          },
        },
      ];

      Vue.nextTick(() => {
        const memberImage = document.querySelector('.approvers-list img');

        expect(memberImage.src).toContain(avatarUrl);
        done();
      });
    });

    it('allows to add multiple approvers withoutd duplicate-key errors', done => {
      vm.approvedBy = [
        {
          user: {
            username: 'Tanuki',
            avatar_url: avatarUrl,
          },
        },
        {
          user: {
            username: 'Tanuki2',
            avatar_url: avatarUrl,
          },
        },
      ];

      Vue.nextTick(() => {
        const approvers = document.querySelectorAll('.approvers-list img');

        expect(approvers.length).toBe(2);
        done();
      });
    });
  });
});
