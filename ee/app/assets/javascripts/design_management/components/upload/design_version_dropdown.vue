<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import allVersionsMixin from '../../mixins/all_versions';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  mixins: [allVersionsMixin],
  computed: {
    dropdownText() {
      if (
        !this.$route.query.version ||
        Number(this.$route.query.version) === this.allVersions.length
      ) {
        return __('Showing Latest Version');
      }
      const versionNumber = this.getCurrentVersionNumber();
      return sprintf(__('Showing Version #%{versionNumber}'), {
        versionNumber,
      });
    },
    currentVersion() {
      return this.$route.query.version || this.getLatestVersionId();
    },
  },
  methods: {
    getVersionId(versionId) {
      return versionId.match('::Version\/(.+$)')[1]; // eslint-disable-line no-useless-escape
    },
    getLatestVersionId() {
      return this.getVersionId(this.allVersions[0].node.id);
    },
    getCurrentVersionNumber() {
      const versionIndex = this.allVersions.findIndex(
        version => this.getVersionId(version.node.id) === this.$route.query.version,
      );
      return this.allVersions.length - versionIndex;
    },
  },
};
</script>

<template>
  <gl-dropdown :text="dropdownText" variant="link" class="design-version-dropdown">
    <gl-dropdown-item v-for="(version, index) in allVersions" :key="version.node.id">
      <router-link
        class="d-flex js-version-link"
        :to="{ path: $route.path, query: { version: getVersionId(version.node.id) } }"
      >
        <div class="flex-grow-1 ml-2">
          <div>
            <strong
              >{{ __('Version') }} {{ allVersions.length - index }}
              <span v-if="getVersionId(version.node.id) === getLatestVersionId()"
                >({{ __('latest') }})</span
              >
            </strong>
          </div>
        </div>
        <i
          v-if="getVersionId(version.node.id) === currentVersion"
          class="fa fa-check pull-right"
        ></i>
      </router-link>
    </gl-dropdown-item>
  </gl-dropdown>
</template>
