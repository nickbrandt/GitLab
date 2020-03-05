<script>
import {
  GlButton,
  GlFormGroup,
  GlFormRadioGroup,
  GlIcon,
  GlLoadingIcon,
  GlTooltip,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { healthStatusColorMap, healthStatusTextMap } from '../../constants';

export default {
  components: {
    GlButton,
    GlIcon,
    GlLoadingIcon,
    GlFormGroup,
    GlFormRadioGroup,
    GlTooltip,
  },
  props: {
    isEditable: {
      type: Boolean,
      required: false,
      default: false,
    },
    isFetching: {
      type: Boolean,
      required: false,
      default: false,
    },
    status: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      isFormShowing: false,
      selectedStatus: this.status,
      statusOptions: Object.keys(healthStatusTextMap).map(key => ({
        value: key,
        text: healthStatusTextMap[key],
      })),
    };
  },
  computed: {
    statusText() {
      return this.status ? healthStatusTextMap[this.status] : s__('Sidebar|None');
    },
    statusColor() {
      return healthStatusColorMap[this.status];
    },
    tooltipText() {
      let tooltipText = s__('Sidebar|Status');

      if (this.status) {
        tooltipText += `: ${this.statusText}`;
      }

      return tooltipText;
    },
  },
  watch: {
    status(status) {
      this.selectedStatus = status;
    },
  },
  methods: {
    handleFormSubmission() {
      this.$emit('onFormSubmit', this.selectedStatus);
      this.hideForm();
    },
    hideForm() {
      this.isFormShowing = false;
      this.$refs.editButton.focus();
    },
    toggleFormDropdown() {
      this.isFormShowing = !this.isFormShowing;
    },
  },
};
</script>

<template>
  <div class="block">
    <div ref="status" class="sidebar-collapsed-icon">
      <gl-icon name="status-health" :size="14" />

      <gl-loading-icon v-if="isFetching" />
      <p v-else class="collapse-truncated-title px-1">{{ statusText }}</p>
    </div>
    <gl-tooltip :target="() => $refs.status" boundary="viewport" placement="left">
      {{ tooltipText }}
    </gl-tooltip>

    <div class="hide-collapsed">
      <p class="title d-flex justify-content-between">
        {{ s__('Sidebar|Status') }}
        <a
          v-if="isEditable"
          ref="editButton"
          class="btn-link"
          href="#"
          @click="toggleFormDropdown"
          @keydown.esc="hideForm"
        >
          {{ __('Edit') }}
        </a>
      </p>

      <div v-if="isFormShowing" class="dropdown show">
        <form class="dropdown-menu p-3" @submit.prevent="handleFormSubmission">
          <p>
            {{
              __('Choose which status most accurately reflects the current state of this issue:')
            }}
          </p>
          <gl-form-group>
            <gl-form-radio-group
              v-model="selectedStatus"
              :checked="selectedStatus"
              :options="statusOptions"
              stacked
              @keydown.esc.native="hideForm"
            />
          </gl-form-group>
          <gl-form-group class="mb-0">
            <gl-button type="button" class="append-right-10" @click="hideForm">
              {{ __('Cancel') }}
            </gl-button>
            <gl-button type="submit" variant="success">
              {{ __('Save') }}
            </gl-button>
          </gl-form-group>
        </form>
      </div>

      <gl-loading-icon v-if="isFetching" :inline="true" />
      <p v-else class="value m-0" :class="{ 'no-value': !status }">
        <gl-icon
          v-if="status"
          name="severity-low"
          :size="14"
          class="align-bottom mr-2"
          :class="statusColor"
        />
        {{ statusText }}
      </p>
    </div>
  </div>
</template>
