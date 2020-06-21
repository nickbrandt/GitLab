import Vue from 'vue';
import LicenseIssueBody from 'ee/vue_shared/license_compliance/components/add_license_form.vue';
import mountComponent from 'helpers/vue_mount_component_helper';
import { LICENSE_APPROVAL_STATUS } from 'ee/vue_shared/license_compliance/constants';

describe('AddLicenseForm', () => {
  const Component = Vue.extend(LicenseIssueBody);
  let vm;

  const findSubmitButton = () => vm.$el.querySelector('.js-submit');
  const findCancelButton = () => vm.$el.querySelector('.js-cancel');

  beforeEach(() => {
    window.gon = { features: { licenseComplianceDeniesMr: false } };
    vm = mountComponent(Component);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('interaction', () => {
    it('clicking the Submit button submits the data and closes the form', done => {
      const name = 'LICENSE_TEST';
      jest.spyOn(vm, '$emit').mockImplementation(() => {});
      vm.approvalStatus = LICENSE_APPROVAL_STATUS.ALLOWED;
      vm.licenseName = name;

      Vue.nextTick(() => {
        const linkEl = findSubmitButton();
        linkEl.click();

        expect(vm.$emit).toHaveBeenCalledWith('addLicense', {
          newStatus: LICENSE_APPROVAL_STATUS.ALLOWED,
          license: { name },
        });

        done();
      });
    });

    it('clicking the Cancel button closes the form', () => {
      const linkEl = findCancelButton();
      jest.spyOn(vm, '$emit').mockImplementation(() => {});
      linkEl.click();

      expect(vm.$emit).toHaveBeenCalledWith('closeForm');
    });
  });

  describe('computed', () => {
    describe('submitDisabled', () => {
      it('is true if the approvalStatus is empty', () => {
        vm.licenseName = 'FOO';
        vm.approvalStatus = '';

        expect(vm.submitDisabled).toBe(true);
      });

      it('is true if the licenseName is empty', () => {
        vm.licenseName = '';
        vm.approvalStatus = LICENSE_APPROVAL_STATUS.ALLOWED;

        expect(vm.submitDisabled).toBe(true);
      });

      it('is true if the entered license is duplicated', () => {
        vm = mountComponent(Component, { managedLicenses: [{ name: 'FOO' }] });
        vm.licenseName = 'FOO';
        vm.approvalStatus = LICENSE_APPROVAL_STATUS.ALLOWED;

        expect(vm.submitDisabled).toBe(true);
      });
    });

    describe('isInvalidLicense', () => {
      it('is true if the entered license is duplicated', () => {
        vm = mountComponent(Component, { managedLicenses: [{ name: 'FOO' }] });
        vm.licenseName = 'FOO';

        expect(vm.isInvalidLicense).toBe(true);
      });

      it('is false if the entered license is unique', () => {
        vm = mountComponent(Component, { managedLicenses: [{ name: 'FOO' }] });
        vm.licenseName = 'FOO2';

        expect(vm.isInvalidLicense).toBe(false);
      });
    });
  });

  describe('template', () => {
    it('renders the license select dropdown', () => {
      const dropdownElement = vm.$el.querySelector('#js-license-dropdown');

      expect(dropdownElement).not.toBeNull();
    });

    it('renders the license approval radio buttons dropdown', () => {
      const radioButtonParents = vm.$el.querySelectorAll('.form-check');

      expect(radioButtonParents).toHaveLength(2);
      expect(radioButtonParents[0].innerText.trim()).toBe('Allow');
      expect(radioButtonParents[0].querySelector('.form-check-input')).not.toBeNull();
      expect(radioButtonParents[1].innerText.trim()).toBe('Deny');
      expect(radioButtonParents[1].querySelector('.form-check-input')).not.toBeNull();
    });

    it('renders error text, if there is a duplicate license', done => {
      vm = mountComponent(Component, { managedLicenses: [{ name: 'FOO' }] });
      vm.licenseName = 'FOO';
      Vue.nextTick(() => {
        const feedbackElement = vm.$el.querySelector('.invalid-feedback');

        expect(feedbackElement).not.toBeNull();
        expect(feedbackElement.classList).toContain('d-block');
        expect(feedbackElement.innerText.trim()).toBe(
          'This license already exists in this project.',
        );
        done();
      });
    });

    it('shows dropdown descriptions, if licenseComplianceDeniesMr feature flag is enabled', done => {
      window.gon = { features: { licenseComplianceDeniesMr: true } };
      vm = mountComponent(Component, { managedLicenses: [{ name: 'FOO' }] });
      vm.licenseName = 'FOO';
      Vue.nextTick(() => {
        const feedbackElement = vm.$el.querySelectorAll('.text-secondary');

        expect(feedbackElement[0].innerText.trim()).toBe(
          'Acceptable license to be used in the project',
        );

        expect(feedbackElement[1].innerText.trim()).toBe(
          'Disallow merge request if detected and will instruct developer to remove',
        );
        done();
      });
    });

    it('does not show dropdown descriptions, if licenseComplianceDeniesMr feature flag is disabled', done => {
      vm = mountComponent(Component, { managedLicenses: [{ name: 'FOO' }] });
      vm.licenseName = 'FOO';
      Vue.nextTick(() => {
        const feedbackElement = vm.$el.querySelectorAll('.text-secondary');

        expect(feedbackElement.length).toBe(0);
        done();
      });
    });

    it('disables submit, if the form is invalid', done => {
      vm.licenseName = '';
      Vue.nextTick(() => {
        expect(vm.submitDisabled).toBe(true);

        const submitButton = findSubmitButton();

        expect(submitButton).not.toBeNull();
        expect(submitButton.disabled).toBe(true);
        done();
      });
    });

    it('disables submit and cancel while a new license is being added', done => {
      vm.loading = true;
      Vue.nextTick(() => {
        const submitButton = findSubmitButton();
        const cancelButton = findCancelButton();

        expect(submitButton).not.toBeNull();
        expect(submitButton.disabled).toBe(true);
        expect(cancelButton).not.toBeNull();
        expect(cancelButton.disabled).toBe(true);
        done();
      });
    });
  });
});
