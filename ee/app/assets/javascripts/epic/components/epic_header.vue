<script>
import { mapState, mapGetters, mapActions } from 'vuex';

import { __ } from '~/locale';

import tooltip from '~/vue_shared/directives/tooltip';
import Icon from '~/vue_shared/components/icon.vue';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

import epicUtils from '../utils/epic_utils';
import { statusType } from '../constants';

export default {
  directives: {
    tooltip,
  },
  components: {
    Icon,
    LoadingButton,
    UserAvatarLink,
    TimeagoTooltip,
  },
  computed: {
    ...mapState([
      'epicDeleteInProgress',
      'epicStatusChangeInProgress',
      'author',
      'created',
      'canUpdate',
    ]),
    ...mapGetters(['isEpicOpen']),
    statusIcon() {
      return this.isEpicOpen ? 'issue-open-m' : 'mobile-issue-close';
    },
    statusText() {
      return this.isEpicOpen ? __('Open') : __('Closed');
    },
    actionButtonClass() {
      return `btn btn-grouped js-btn-epic-action qa-close-reopen-epic-button ${
        this.isEpicOpen ? 'btn-close' : 'btn-open'
      }`;
    },
    actionButtonText() {
      return this.isEpicOpen ? __('Close epic') : __('Reopen epic');
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
    ...mapActions(['requestEpicStatusChangeSuccess', 'toggleEpicStatus']),
  },
};
</script>

<template>
  <div class="detail-page-header">
    <div class="detail-page-header-body">
      <div
        :class="{ 'status-box-open': isEpicOpen, 'status-box-issue-closed': !isEpicOpen }"
        class="issuable-status-box status-box"
      >
        <icon :name="statusIcon" css-classes="d-block d-sm-none" />
        <span class="d-none d-sm-block">{{ statusText }}</span>
      </div>
      <div class="issuable-meta">
        {{ __('Opened') }}
        <timeago-tooltip :time="created" />
        {{ __('by') }}
        <strong>
          <user-avatar-link
            :link-href="author.url"
            :img-src="author.src"
            :img-size="24"
            :tooltip-text="author.username"
            :username="author.name"
            img-css-classes="avatar-inline"
          />
        </strong>
      </div>
    </div>
    <div v-if="canUpdate" class="detail-page-header-actions js-issuable-actions">
      <loading-button
        :label="actionButtonText"
        :loading="epicStatusChangeInProgress"
        :container-class="actionButtonClass"
        @click="toggleEpicStatus(isEpicOpen)"
      />
    </div>
  </div>
</template>
