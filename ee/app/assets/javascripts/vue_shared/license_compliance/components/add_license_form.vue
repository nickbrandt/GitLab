<script>
import { GlDeprecatedButton } from '@gitlab/ui';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import { LICENSE_APPROVAL_STATUS } from '../constants';
import AddLicenseFormDropdown from './add_license_form_dropdown.vue';
import { s__ } from '~/locale';

export default {
  name: 'AddLicenseForm',
  components: {
    AddLicenseFormDropdown,
    GlDeprecatedButton,
    LoadingButton,
  },
  LICENSE_APPROVAL_STATUS,
  approvalStatusOptions: [
    {
      value: LICENSE_APPROVAL_STATUS.ALLOWED,
      label: s__('LicenseCompliance|Allow'),
      description: s__('LicenseCompliance|Acceptable license to be used in the project'),
    },
    {
      value: LICENSE_APPROVAL_STATUS.DENIED,
      label: s__('LicenseCompliance|Deny'),
      description: s__(
        'LicenseCompliance|Disallow merge request if detected and will instruct developer to remove',
      ),
    },
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
    isDescriptionEnabled() {
      return gon.features.licenseComplianceDeniesMr;
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
      <div
        v-for="option in $options.approvalStatusOptions"
        :key="option.value"
        class="form-check"
        v-bind:class="{ 'mb-3': isDescriptionEnabled }"
      >
        <input
          :id="`js-${option.value}-license-radio`"
          v-model="approvalStatus"
          class="form-check-input"
          type="radio"
          :data-qa-selector="`${option.value}_license_radio`"
          :value="option.value"
        />
        <label :for="`js-${option.value}-license-radio`" class="form-check-label pt-1">
          {{ option.label }}
        </label>
        <div v-if="isDescriptionEnabled" class="text-secondary">
          {{ option.description }}
        </div>
      </div>
    </div>
    <loading-button
      class="js-submit"
      :disabled="submitDisabled"
      :loading="loading"
      container-class="btn btn-success btn-align-content d-inline-flex"
      :label="s__('LicenseCompliance|Submit')"
      data-qa-selector="add_license_submit_button"
      @click="addLicense"
    />
    <gl-deprecated-button
      class="js-cancel"
      variant="default"
      :disabled="loading"
      @click="closeForm"
    >
      {{ s__('LicenseCompliance|Cancel') }}
    </gl-deprecated-button>
  </div>
</template>
