<script>
import { GlAvatar, GlDropdown, GlDropdownItem, GlSprintf } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import allVersionsMixin from '../../mixins/all_versions';
import { findVersionId } from '../../utils/design_management_utils';

export default {
  components: {
    GlAvatar,
    GlDropdown,
    GlSprintf,
    GlDropdownItem,
    TimeAgoTooltip,
  },
  mixins: [allVersionsMixin],
  computed: {
    queryVersion() {
      return this.$route.query.version;
    },
    currentVersionIdx() {
      if (!this.queryVersion) return 0;

      const idx = this.allVersions.findIndex(
        version => this.findVersionId(version.node.id) === this.queryVersion,
      );

      // if the currentVersionId isn't a valid version (i.e. not in allVersions)
      // then return the latest version (index 0)
      return idx !== -1 ? idx : 0;
    },
    currentVersionId() {
      if (this.queryVersion) return this.queryVersion;

      const currentVersion = this.allVersions[this.currentVersionIdx];
      return this.findVersionId(currentVersion.node.id);
    },
    dropdownText() {
      if (this.isLatestVersion) {
        return __('Showing Latest Version');
      }
      // allVersions is sorted in reverse chronological order (latest first)
      const currentVersionNumber = this.allVersions.length - this.currentVersionIdx;

      return sprintf(__('Showing Version #%{versionNumber}'), {
        versionNumber: currentVersionNumber,
      });
    },
  },
  methods: {
    findVersionId,
  },
};
</script>

<template>
  <gl-dropdown :text="dropdownText" variant="link" class="design-version-dropdown">
    <gl-dropdown-item
      v-for="({ node }, index) in allVersions"
      :key="node.id"
      class="border-top"
      :class="{ 'bg-light': findVersionId(node.id) === currentVersionId }"
    >
      <router-link
        class="d-flex js-version-link px-0"
        :to="{ path: $route.path, query: { version: findVersionId(node.id) } }"
      >
        <div class="flex-shrink-0">
          <gl-avatar :src="node.author.avatarUrl" :size="32" />
        </div>
        <div class="flex-grow-1 mx-2">
          <div>
            <strong
              >{{ __('Version') }} {{ allVersions.length - index }}
              <span v-if="findVersionId(node.id) === latestVersionId">({{ __('latest') }})</span>
            </strong>
            <div class="text-muted mt-1">
              <gl-sprintf :message="__('%{author} updated the designs')">
                <template #author>{{ node.author.name }}</template>
              </gl-sprintf>
              <br />
              <time-ago-tooltip :time="node.createdAt" tooltip-placement="bottom" />
            </div>
          </div>
        </div>
        <i
          v-if="findVersionId(node.id) === currentVersionId"
          class="fa fa-check pull-right align-self-center"
        ></i>
      </router-link>
    </gl-dropdown-item>
  </gl-dropdown>
</template>
