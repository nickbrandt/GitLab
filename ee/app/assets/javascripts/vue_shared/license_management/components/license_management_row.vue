<script>
import { mapActions } from 'vuex';
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { s__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import IssueStatusIcon from '~/reports/components/issue_status_icon.vue';
import { getIssueStatusFromLicenseStatus } from 'ee/vue_shared/license_management/store/utils';

import { LICENSE_APPROVAL_STATUS } from '../constants';

const visibleClass = 'visible';
const invisibleClass = 'invisible';

export default {
  name: 'LicenseManagementRow',
  components: {
    GlDropdown,
    GlDropdownItem,
    Icon,
    IssueStatusIcon,
  },
  props: {
    license: {
      type: Object,
      required: true,
      validator: license =>
        Boolean(license.name) &&
        Object.values(LICENSE_APPROVAL_STATUS).includes(license.approvalStatus),
    },
  },
  LICENSE_APPROVAL_STATUS,
  [LICENSE_APPROVAL_STATUS.APPROVED]: s__('LicenseCompliance|Approved'),
  [LICENSE_APPROVAL_STATUS.BLACKLISTED]: s__('LicenseCompliance|Blacklisted'),
  computed: {
    approveIconClass() {
      return this.license.approvalStatus === LICENSE_APPROVAL_STATUS.APPROVED
        ? visibleClass
        : invisibleClass;
    },
    blacklistIconClass() {
      return this.license.approvalStatus === LICENSE_APPROVAL_STATUS.BLACKLISTED
        ? visibleClass
        : invisibleClass;
    },
    status() {
      return getIssueStatusFromLicenseStatus(this.license.approvalStatus);
    },
    dropdownText() {
      return this.$options[this.license.approvalStatus];
    },
  },
  methods: {
    ...mapActions(['setLicenseInModal', 'approveLicense', 'blacklistLicense']),
  },
};
</script>
<template>
  <div data-qa-selector="license_compliance_row">
    <issue-status-icon :status="status" class="float-left append-right-default" />
    <span class="js-license-name" data-qa-selector="license_name_content">{{ license.name }}</span>
    <div class="float-right">
      <div class="d-flex">
        <gl-dropdown
          :text="dropdownText"
          toggle-class="d-flex justify-content-between align-items-center"
          right
        >
          <gl-dropdown-item @click="approveLicense(license)">
            <icon :class="approveIconClass" name="mobile-issue-close" />
            {{ $options[$options.LICENSE_APPROVAL_STATUS.APPROVED] }}
          </gl-dropdown-item>
          <gl-dropdown-item @click="blacklistLicense(license)">
            <icon :class="blacklistIconClass" name="mobile-issue-close" />
            {{ $options[$options.LICENSE_APPROVAL_STATUS.BLACKLISTED] }}
          </gl-dropdown-item>
        </gl-dropdown>
        <button
          class="btn btn-blank js-remove-button"
          type="button"
          data-toggle="modal"
          data-target="#modal-license-delete-confirmation"
          @click="setLicenseInModal(license)"
        >
          <icon name="remove" />
        </button>
      </div>
    </div>
  </div>
</template>
