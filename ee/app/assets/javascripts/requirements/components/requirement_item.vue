<script>
import { escape } from 'lodash';
import {
  GlPopover,
  GlLink,
  GlAvatar,
  GlDeprecatedButton,
  GlIcon,
  GlLoadingIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { getTimeago } from '~/lib/utils/datetime_utility';
import timeagoMixin from '~/vue_shared/mixins/timeago';

import RequirementForm from './requirement_form.vue';
import RequirementStatusBadge from './requirement_status_badge.vue';

import { FilterState } from '../constants';

export default {
  components: {
    GlPopover,
    GlLink,
    GlAvatar,
    GlDeprecatedButton,
    GlIcon,
    GlLoadingIcon,
    RequirementForm,
    RequirementStatusBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  props: {
    requirement: {
      type: Object,
      required: true,
      validator: value =>
        [
          'iid',
          'state',
          'userPermissions',
          'title',
          'createdAt',
          'updatedAt',
          'author',
          'testReports',
        ].every(prop => value[prop]),
    },
    showUpdateForm: {
      type: Boolean,
      required: false,
      default: false,
    },
    updateRequirementRequestActive: {
      type: Boolean,
      required: false,
      default: false,
    },
    stateChangeRequestActive: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    reference() {
      return `REQ-${this.requirement.iid}`;
    },
    canUpdate() {
      return this.requirement.userPermissions.updateRequirement;
    },
    canArchive() {
      return this.requirement.userPermissions.adminRequirement;
    },
    createdAt() {
      return sprintf(__('created %{timeAgo}'), {
        timeAgo: escape(getTimeago().format(this.requirement.createdAt)),
      });
    },
    updatedAt() {
      return sprintf(__('updated %{timeAgo}'), {
        timeAgo: escape(getTimeago().format(this.requirement.updatedAt)),
      });
    },
    isArchived() {
      return this.requirement?.state === FilterState.archived;
    },
    author() {
      return this.requirement.author;
    },
    testReport() {
      return this.requirement.testReports.nodes[0];
    },
    showIssuableMetaActions() {
      return Boolean(this.canUpdate || this.canArchive || this.testReport);
    },
  },
  methods: {
    /**
     * This is needed as an independent method since
     * when user changes current page, `$refs.authorLink`
     * will be null until next page results are loaded & rendered.
     */
    getAuthorPopoverTarget() {
      if (this.$refs.authorLink) {
        return this.$refs.authorLink.$el;
      }
      return '';
    },
    handleUpdateRequirementSave(params) {
      this.$emit('updateSave', params);
    },
    handleArchiveClick() {
      this.$emit('archiveClick', {
        iid: this.requirement.iid,
        state: FilterState.archived,
      });
    },
    handleReopenClick() {
      this.$emit('reopenClick', {
        iid: this.requirement.iid,
        state: FilterState.opened,
      });
    },
  },
};
</script>

<template>
  <li class="issue requirement" :class="{ 'disabled-content': stateChangeRequestActive }">
    <requirement-form
      v-if="showUpdateForm"
      :requirement="requirement"
      :requirement-request-active="updateRequirementRequestActive"
      @save="handleUpdateRequirementSave"
      @cancel="$emit('updateCancel')"
    />
    <div v-else class="issue-box">
      <div class="issuable-info-container">
        <span class="issuable-reference text-muted d-none d-sm-block mr-2">{{ reference }}</span>
        <div class="issuable-main-info">
          <span class="issuable-reference text-muted d-block d-sm-none">{{ reference }}</span>
          <div class="issue-title title">
            <span class="issue-title-text">{{ requirement.title }}</span>
          </div>
          <div class="issuable-info d-none d-sm-inline-block">
            <span class="issuable-authored">
              <span
                v-gl-tooltip:tooltipcontainer.bottom
                :title="tooltipTitle(requirement.createdAt)"
                >{{ createdAt }}</span
              >
              {{ __('by') }}
              <gl-link ref="authorLink" class="author-link js-user-link" :href="author.webUrl">
                <span class="author">{{ author.name }}</span>
              </gl-link>
            </span>
            <span
              v-gl-tooltip:tooltipcontainer.bottom
              :title="tooltipTitle(requirement.updatedAt)"
              class="issuable-updated-at"
              >&middot; {{ updatedAt }}</span
            >
          </div>
          <requirement-status-badge
            v-if="testReport"
            :test-report="testReport"
            class="d-block d-sm-none"
          />
        </div>
        <div class="issuable-meta">
          <ul v-if="showIssuableMetaActions" class="controls flex-column flex-sm-row">
            <requirement-status-badge
              v-if="testReport"
              :test-report="testReport"
              element-type="li"
              class="d-none d-sm-block"
            />
            <li v-if="canUpdate && !isArchived" class="requirement-edit d-sm-block">
              <gl-deprecated-button
                v-gl-tooltip
                size="sm"
                class="border-0"
                :title="__('Edit')"
                @click="$emit('editClick', requirement.iid)"
              >
                <gl-icon name="pencil" />
              </gl-deprecated-button>
            </li>
            <li v-if="canArchive && !isArchived" class="requirement-archive d-sm-block">
              <gl-deprecated-button
                v-gl-tooltip
                size="sm"
                class="border-0"
                :title="__('Archive')"
                @click="handleArchiveClick"
              >
                <gl-icon v-if="!stateChangeRequestActive" name="archive" />
                <gl-loading-icon v-else />
              </gl-deprecated-button>
            </li>
            <li v-if="canArchive && isArchived" class="requirement-reopen d-sm-block">
              <gl-deprecated-button
                size="xs"
                class="p-2"
                :loading="stateChangeRequestActive"
                @click="handleReopenClick"
                >{{ __('Reopen') }}</gl-deprecated-button
              >
            </li>
          </ul>
        </div>
      </div>
    </div>
    <gl-popover :target="getAuthorPopoverTarget()" triggers="hover focus" placement="top">
      <div class="user-popover p-0 d-flex">
        <div class="p-1 flex-shrink-1">
          <gl-avatar :entity-name="author.name" :alt="author.name" :src="author.avatarUrl" />
        </div>
        <div class="p-1 w-100">
          <h5 class="m-0">{{ author.name }}</h5>
          <div class="text-secondary mb-2">@{{ author.username }}</div>
        </div>
      </div>
    </gl-popover>
  </li>
</template>
