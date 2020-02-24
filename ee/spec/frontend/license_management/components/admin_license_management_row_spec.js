import Vue from 'vue';
import Vuex from 'vuex';

import AdminLicenseManagementRow from 'ee/vue_shared/license_management/components/admin_license_management_row.vue';
import { LICENSE_APPROVAL_STATUS } from 'ee/vue_shared/license_management/constants';

import { mountComponentWithStore } from 'helpers/vue_mount_component_helper';
import { approvedLicense } from '../mock_data';

const visibleClass = 'visible';
const invisibleClass = 'invisible';

Vue.use(Vuex);

describe('AdminLicenseManagementRow', () => {
  const Component = Vue.extend(AdminLicenseManagementRow);

  let vm;
  let store;
  let actions;

  const findNthDropdown = num => [...vm.$el.querySelectorAll('.dropdown-item')][num];
  const findNthDropdownIcon = num => findNthDropdown(num).querySelector('svg');

  beforeEach(() => {
    actions = {
      setLicenseInModal: jest.fn(),
      approveLicense: jest.fn(),
      blacklistLicense: jest.fn(),
    };

    store = new Vuex.Store({
      modules: {
        licenseManagement: {
          namespaced: true,
          state: {},
          actions,
        },
      },
    });

    const props = { license: approvedLicense };

    vm = mountComponentWithStore(Component, { props, store });
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('approved license', () => {
    beforeEach(done => {
      vm.license = { ...approvedLicense, approvalStatus: LICENSE_APPROVAL_STATUS.APPROVED };
      Vue.nextTick(done);
    });

    describe('computed', () => {
      it('dropdownText returns `Allowed`', () => {
        expect(vm.dropdownText).toBe('Allowed');
      });

      it('isApproved returns `true`', () => {
        expect(vm.approveIconClass).toBe(visibleClass);
      });

      it('isBlacklisted returns `false`', () => {
        expect(vm.blacklistIconClass).toBe(invisibleClass);
      });
    });

    describe('template', () => {
      it('first dropdown element should have a visible icon', () => {
        const firstOption = findNthDropdownIcon(0);

        expect(firstOption.classList).toContain(visibleClass);
      });

      it('second dropdown element should have no visible icon', () => {
        const secondOption = findNthDropdownIcon(1);

        expect(secondOption.classList).toContain(invisibleClass);
      });
    });
  });

  describe('blacklisted license', () => {
    beforeEach(done => {
      vm.license = { ...approvedLicense, approvalStatus: LICENSE_APPROVAL_STATUS.BLACKLISTED };
      Vue.nextTick(done);
    });

    describe('computed', () => {
      it('dropdownText returns `Denied`', () => {
        expect(vm.dropdownText).toBe('Denied');
      });

      it('isApproved returns `false`', () => {
        expect(vm.approveIconClass).toBe(invisibleClass);
      });

      it('isBlacklisted returns `true`', () => {
        expect(vm.blacklistIconClass).toBe(visibleClass);
      });
    });

    describe('template', () => {
      it('first dropdown element should have no visible icon', () => {
        const firstOption = findNthDropdownIcon(0);

        expect(firstOption.classList).toContain(invisibleClass);
      });

      it('second dropdown element should have a visible icon', () => {
        const secondOption = findNthDropdownIcon(1);

        expect(secondOption.classList).toContain(visibleClass);
      });
    });
  });

  describe('interaction', () => {
    it('triggering setLicenseInModal by clicking the cancel button', () => {
      const linkEl = vm.$el.querySelector('.js-remove-button');
      linkEl.click();

      expect(actions.setLicenseInModal).toHaveBeenCalled();
    });

    it('triggering approveLicense by clicking the first dropdown option', () => {
      const linkEl = findNthDropdown(0);
      linkEl.click();

      expect(actions.approveLicense).toHaveBeenCalled();
    });

    it('triggering approveLicense blacklistLicense by clicking the second dropdown option', () => {
      const linkEl = findNthDropdown(1);
      linkEl.click();

      expect(actions.blacklistLicense).toHaveBeenCalled();
    });
  });

  describe('template', () => {
    it('renders component container element as a div', () => {
      expect(vm.$el.tagName).toBe('DIV');
    });

    it('renders status icon', () => {
      const iconEl = vm.$el.querySelector('.report-block-list-icon');

      expect(iconEl).not.toBeNull();
    });

    it('renders license name', () => {
      const nameEl = vm.$el.querySelector('.js-license-name');

      expect(nameEl.innerText.trim()).toBe(approvedLicense.name);
    });

    it('renders the removal button', () => {
      const buttonEl = vm.$el.querySelector('.js-remove-button');

      expect(buttonEl).not.toBeNull();
      expect(buttonEl.querySelector('.ic-remove')).not.toBeNull();
    });

    it('renders computed property dropdownText into dropdown toggle', () => {
      const dropdownEl = vm.$el.querySelector('.dropdown-toggle');

      expect(dropdownEl.innerText.trim()).toBe(vm.dropdownText);
    });

    it('renders the dropdown with `Allowed` and `Denied` options', () => {
      const dropdownEl = vm.$el.querySelector('.dropdown');

      expect(dropdownEl).not.toBeNull();

      const firstOption = findNthDropdown(0);

      expect(firstOption).not.toBeNull();
      expect(firstOption.innerText.trim()).toBe('Allowed');

      const secondOption = findNthDropdown(1);

      expect(secondOption).not.toBeNull();
      expect(secondOption.innerText.trim()).toBe('Denied');
    });
  });
});
