<script>
import { mapActions, mapState } from 'vuex';
import SafeLink from 'ee/vue_shared/components/safe_link.vue';
import { s__ } from '~/locale';
import DeprecatedModal2 from '~/vue_shared/components/deprecated_modal_2.vue';
import LicensePackages from './license_packages.vue';
import { LICENSE_APPROVAL_STATUS } from '../constants';

export default {
  name: 'LicenseSetApprovalStatusModal',
  components: { SafeLink, LicensePackages, GlModal: DeprecatedModal2 },
  computed: {
    ...mapState(['currentLicenseInModal', 'canManageLicenses']),
    headerTitleText() {
      if (!this.canManageLicenses) {
        return s__('LicenseCompliance|License details');
      }
      if (this.canApprove) {
        return s__('LicenseCompliance|Approve license?');
      }
      return s__('LicenseCompliance|Blacklist license?');
    },
    canApprove() {
      return (
        this.canManageLicenses &&
        this.currentLicenseInModal &&
        this.currentLicenseInModal.approvalStatus !== LICENSE_APPROVAL_STATUS.APPROVED
      );
    },
    canBlacklist() {
      return (
        this.canManageLicenses &&
        this.currentLicenseInModal &&
        this.currentLicenseInModal.approvalStatus !== LICENSE_APPROVAL_STATUS.BLACKLISTED
      );
    },
  },
  methods: {
    ...mapActions(['resetLicenseInModal', 'approveLicense', 'blacklistLicense']),
  },
};
</script>
<template>
  <gl-modal
    id="modal-set-license-approval"
    :header-title-text="headerTitleText"
    modal-size="lg"
    data-qa-selector="license_management_modal"
    @cancel="resetLicenseInModal"
  >
    <slot v-if="currentLicenseInModal">
      <div class="row prepend-top-10 append-bottom-10 js-license-name">
        <label class="col-sm-3 text-right font-weight-bold">
          {{ s__('LicenseCompliance|License') }}:
        </label>
        <div class="col-sm-9 text-secondary">{{ currentLicenseInModal.name }}</div>
      </div>
      <div
        v-if="currentLicenseInModal.url"
        class="row prepend-top-10 append-bottom-10 js-license-url"
      >
        <label class="col-sm-3 text-right font-weight-bold">
          {{ s__('LicenseCompliance|URL') }}:
        </label>
        <div class="col-sm-9 text-secondary">
          <safe-link
            :href="currentLicenseInModal.url"
            target="_blank"
            rel="noopener noreferrer nofollow"
            >{{ currentLicenseInModal.url }}</safe-link
          >
        </div>
      </div>
      <div class="row prepend-top-10 append-bottom-10 js-license-packages">
        <label class="col-sm-3 text-right font-weight-bold">
          {{ s__('LicenseCompliance|Packages') }}:
        </label>
        <license-packages
          :packages="currentLicenseInModal.packages"
          class="col-sm-9 text-secondary"
        />
      </div>
    </slot>
    <template slot="footer">
      <button
        type="button"
        class="btn js-modal-cancel-action"
        data-dismiss="modal"
        @click="resetLicenseInModal"
      >
        {{ s__('Modal|Cancel') }}
      </button>
      <button
        v-if="canBlacklist"
        class="btn btn-remove btn-inverted js-modal-secondary-action"
        data-dismiss="modal"
        data-qa-selector="blacklist_license_button"
        @click="blacklistLicense(currentLicenseInModal)"
      >
        {{ s__('LicenseCompliance|Blacklist license') }}
      </button>
      <button
        v-if="canApprove"
        type="button"
        class="btn btn-success js-modal-primary-action"
        data-dismiss="modal"
        data-qa-selector="approve_license_button"
        @click="approveLicense(currentLicenseInModal)"
      >
        {{ s__('LicenseCompliance|Approve license') }}
      </button>
    </template>
  </gl-modal>
</template>
