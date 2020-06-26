<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import { GlButton, GlIcon } from '@gitlab/ui';

import { __ } from '~/locale';

import tooltip from '~/vue_shared/directives/tooltip';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import epicUtils from '../utils/epic_utils';
import { statusType } from '../constants';

export default {
  directives: {
    tooltip,
  },
  components: {
    GlIcon,
    GlButton,
    UserAvatarLink,
    TimeagoTooltip,
    GitlabTeamMemberBadge: () =>
      import('ee_component/vue_shared/components/user_avatar/badges/gitlab_team_member_badge.vue'),
  },
  mixins: [glFeatureFlagsMixin()],
  computed: {
    ...mapState([
      'sidebarCollapsed',
      'epicDeleteInProgress',
      'epicStatusChangeInProgress',
      'author',
      'created',
      'canCreate',
      'canUpdate',
      'confidential',
      'newEpicWebUrl',
    ]),
    ...mapGetters(['isEpicOpen']),
    statusIcon() {
      return this.isEpicOpen ? 'issue-open-m' : 'mobile-issue-close';
    },
    statusText() {
      return this.isEpicOpen ? __('Open') : __('Closed');
    },
    actionButtonClass() {
      // False positive css classes
      // https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/24
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `js-btn-epic-action qa-close-reopen-epic-button ${
        this.isEpicOpen ? 'btn-close' : 'btn-open'
      }`;
    },
    actionButtonText() {
      return this.isEpicOpen ? __('Close epic') : __('Reopen epic');
    },
    userCanCreate() {
      return this.canCreate && this.glFeatures.createEpicForm;
    },
  },
  mounted() {
    /**
     * This event is triggered from Notes app
     * when user clicks on `Close` button below
     * comment form.
     *
     * When event is triggered, we want to reflect Epic status change
     * across the UI so we directly call `requestEpicStatusChangeSuccess` action
     * to update store state.
     */
    epicUtils.bindDocumentEvent('issuable_vue_app:change', (e, isClosed) => {
      const isEpicOpen = e.detail ? !e.detail.isClosed : !isClosed;
      this.requestEpicStatusChangeSuccess({
        state: isEpicOpen ? statusType.open : statusType.close,
      });
    });
  },
  methods: {
    ...mapActions(['toggleSidebar', 'requestEpicStatusChangeSuccess', 'toggleEpicStatus']),
  },
};
</script>

<template>
  <div class="detail-page-header gl-flex-wrap gl-py-3">
    <div class="detail-page-header-body">
      <div
        :class="{ 'status-box-open': isEpicOpen, 'status-box-issue-closed': !isEpicOpen }"
        class="issuable-status-box status-box"
      >
        <gl-icon :name="statusIcon" class="d-block d-sm-none" />
        <span class="d-none d-sm-block">{{ statusText }}</span>
      </div>
      <div class="issuable-meta">
        <div v-if="confidential" class="issuable-warning-icon inline">
          <gl-icon name="eye-slash" class="icon" />
        </div>
        {{ __('Opened') }}
        <timeago-tooltip :time="created" />
        {{ __('by') }}
        <strong class="text-nowrap">
          <user-avatar-link
            :link-href="author.url"
            :img-src="author.src"
            :img-size="24"
            :tooltip-text="author.username"
            :username="author.name"
            img-css-classes="avatar-inline"
          />
          <gitlab-team-member-badge
            v-if="author && author.isGitlabEmployee"
            ref="gitlabTeamMemberBadge"
          />
        </strong>
      </div>
    </div>
    <gl-button
      :aria-label="__('Toggle sidebar')"
      class="float-right gl-display-block d-sm-none gl-align-self-center gutter-toggle issuable-gutter-toggle js-sidebar-toggle"
      type="button"
      @click="toggleSidebar({ sidebarCollapsed })"
    >
      <i class="fa fa-angle-double-left"></i>
    </gl-button>
    <div
      class="detail-page-header-actions gl-display-flex gl-flex-wrap gl-align-items-center gl-w-full gl-w-sm-auto js-issuable-actions"
    >
      <gl-button
        v-if="canUpdate"
        :loading="epicStatusChangeInProgress"
        :class="actionButtonClass"
        category="secondary"
        variant="warning"
        class="gl-mt-3 gl-mt-sm-0 gl-w-full gl-w-sm-auto"
        @click="toggleEpicStatus(isEpicOpen)"
      >
        {{ actionButtonText }}
      </gl-button>
      <gl-button
        v-if="userCanCreate"
        :href="newEpicWebUrl"
        data-testid="new-epic-button"
        class="gl-mt-3 gl-mt-sm-0 gl-ml-sm-3 gl-w-full gl-w-sm-auto"
        category="secondary"
        variant="success"
      >
        {{ __('New epic') }}
      </gl-button>
    </div>
  </div>
</template>
