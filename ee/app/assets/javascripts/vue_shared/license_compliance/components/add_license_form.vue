<script>
import { GlButton } from '@gitlab/ui';
import { LICENSE_APPROVAL_STATUS } from '../constants';
import AddLicenseFormDropdown from './add_license_form_dropdown.vue';
import { s__ } from '~/locale';

export default {
  name: 'AddLicenseForm',
  components: {
    AddLicenseFormDropdown,
    GlButton,
  },
  LICENSE_APPROVAL_STATUS,
  approvalStatusOptions: [
    { value: LICENSE_APPROVAL_STATUS.ALLOWED, label: s__('LicenseCompliance|Allow') },
    { value: LICENSE_APPROVAL_STATUS.DENIED, label: s__('LicenseCompliance|Deny') },
  ],
  props: {
    managedLicenses: {
      type: Array,
      required: false,
      default: () => [],
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      approvalStatus: '',
      licenseName: '',
    };
  },
  computed: {
    isInvalidLicense() {
      return this.managedLicenses.some(({ name }) => name === this.licenseName);
    },
    submitDisabled() {
      return this.isInvalidLicense || this.licenseName.trim() === '' || this.approvalStatus === '';
    },
  },
  methods: {
    addLicense() {
      this.$emit('addLicense', {
        newStatus: this.approvalStatus,
        license: { name: this.licenseName },
      });
    },
    closeForm() {
      this.$emit('closeForm');
    },
  },
};
</script>
<template>
  <div class="col-sm-6 js-add-license-form">
    <div class="form-group">
      <label class="label-bold" for="js-license-dropdown">
        {{ s__('LicenseCompliance|Add license and related policy') }}
      </label>
      <add-license-form-dropdown
        id="js-license-dropdown"
        v-model="licenseName"
        :placeholder="s__('LicenseCompliance|License name')"
      />
      <div class="invalid-feedback" :class="{ 'd-block': isInvalidLicense }">
        {{ s__('LicenseCompliance|This license already exists in this project.') }}
      </div>
    </div>
    <div class="form-group">
      <div v-for="option in $options.approvalStatusOptions" :key="option.value" class="form-check">
        <input
          :id="`js-${option.value}-license-radio`"
          v-model="approvalStatus"
          class="form-check-input"
          type="radio"
          :data-qa-selector="`${option.value}_license_radio`"
          :value="option.value"
        />
        <label :for="`js-${option.value}-license-radio`" class="form-check-label">
          {{ option.label }}
        </label>
      </div>
    </div>
    <div class="gl-display-flex">
      <gl-button
        class="js-submit"
        :disabled="submitDisabled"
        :loading="loading"
        category="primary"
        variant="success"
        data-qa-selector="add_license_submit_button"
        @click="addLicense"
      >
        {{ __('Submit') }}
      </gl-button>
      <gl-button class="js-cancel ml-2" :disabled="loading" @click="closeForm">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </div>
</template>
