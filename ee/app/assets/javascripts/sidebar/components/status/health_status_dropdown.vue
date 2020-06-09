<script>
import Tracking from '~/tracking';
import { GlButton, GlDropdownItem, GlDropdown, GlDropdownDivider } from '@gitlab/ui';
import { s__ } from '~/locale';
import { healthStatusTextMap } from '../../constants';

export default {
  components: {
    GlButton,
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
      if (this.status === null) {
        return s__('No status');
      }

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
  <div class="dropdown dropdown-menu-selectable">
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
</template>
