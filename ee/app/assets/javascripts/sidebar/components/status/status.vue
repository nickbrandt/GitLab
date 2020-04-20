<script>
import Tracking from '~/tracking';
import {
  GlIcon,
  GlButton,
  GlLoadingIcon,
  GlTooltip,
  GlDropdownItem,
  GlDropdown,
  GlDropdownDivider,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { healthStatusTextMap } from '../../constants';

export default {
  components: {
    GlIcon,
    GlButton,
    GlLoadingIcon,
    GlTooltip,
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
  },
  mixins: [Tracking.mixin()],
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
      isDropdownShowing: false,
      selectedStatus: this.status,
      statusOptions: Object.keys(healthStatusTextMap).map(key => ({
        key,
        value: healthStatusTextMap[key],
      })),
    };
  },
  computed: {
    canRemoveStatus() {
      return this.isEditable && this.status;
    },
    statusText() {
      return this.status ? healthStatusTextMap[this.status] : s__('Sidebar|None');
    },
    dropdownText() {
      return this.status ? healthStatusTextMap[this.status] : s__('Select health status');
    },
    tooltipText() {
      let tooltipText = s__('Sidebar|Health status');

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
    handleDropdownClick(status) {
      this.selectedStatus = status;
      this.$emit('onDropdownClick', status);
      this.track('change_health_status', { property: status });
      this.hideDropdown();
    },
    hideDropdown() {
      this.isDropdownShowing = false;
    },
    toggleFormDropdown() {
      this.isDropdownShowing = !this.isDropdownShowing;

      /**
       * We need to programmatically open the dropdown to make the
       * outside click on document close the dropdown.
       */
      const { dropdown } = this.$refs.dropdown.$refs;

      if (dropdown && this.isDropdownShowing) {
        dropdown.show();
      }
    },
    removeStatus() {
      this.handleDropdownClick(null);
    },
    isSelected(status) {
      return this.status === status;
    },
  },
};
</script>

<template>
  <div class="block health-status">
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
        {{ s__('Sidebar|Health status') }}
        <a
          v-if="isEditable"
          ref="editButton"
          class="btn-link"
          href="#"
          @click="toggleFormDropdown"
          @keydown.esc="hideDropdown"
        >
          {{ __('Edit') }}
        </a>
      </p>

      <div
        class="dropdown dropdown-menu-selectable"
        :class="{ show: isDropdownShowing, 'd-none': !isDropdownShowing }"
      >
        <gl-dropdown
          ref="dropdown"
          class="w-100"
          :text="dropdownText"
          @keydown.esc.native="hideDropdown"
          @hide="hideDropdown"
        >
          <div class="dropdown-title">
            <span class="health-title">{{ s__('Sidebar|Assign health status') }}</span>
            <gl-button
              :aria-label="__('Close')"
              variant="link"
              class="dropdown-title-button dropdown-menu-close"
              icon="close"
              @click="hideDropdown"
            />
          </div>

          <div class="dropdown-content dropdown-body">
            <gl-dropdown-item @click="handleDropdownClick(null)">
              <gl-button
                variant="link"
                class="dropdown-item health-dropdown-item"
                :class="{ 'is-active': isSelected(null) }"
              >
                {{ s__('Sidebar|No status') }}
              </gl-button>
            </gl-dropdown-item>

            <gl-dropdown-divider class="divider health-divider" />

            <gl-dropdown-item
              v-for="option in statusOptions"
              :key="option.key"
              @click="handleDropdownClick(option.key)"
            >
              <gl-button
                variant="link"
                class="dropdown-item health-dropdown-item"
                :class="{ 'is-active': isSelected(option.key) }"
              >
                {{ option.value }}
              </gl-button>
            </gl-dropdown-item>
          </div>
        </gl-dropdown>
      </div>

      <gl-loading-icon v-if="isFetching" :inline="true" />
      <p v-else-if="!isDropdownShowing" class="value m-0" :class="{ 'no-value': !status }">
        <span v-if="status" class="text-plain bold">{{ statusText }}</span>
        <span v-else>{{ __('None') }}</span>
      </p>
    </div>
  </div>
</template>
