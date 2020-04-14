<script>
import { mapActions } from 'vuex';
import timeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import GitlabTeamMemberBadge from '~/vue_shared/components/user_avatar/badges/gitlab_team_member_badge.vue';
import $ from 'jquery';

export default {
  components: {
    timeAgoTooltip,
    GitlabTeamMemberBadge,
  },
  props: {
    author: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    createdAt: {
      type: String,
      required: false,
      default: null,
    },
    actionText: {
      type: String,
      required: false,
      default: '',
    },
    noteId: {
      type: [String, Number],
      required: false,
      default: null,
    },
    includeToggle: {
      type: Boolean,
      required: false,
      default: false,
    },
    expanded: {
      type: Boolean,
      required: false,
      default: true,
    },
    showSpinner: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      isUsernameLinkHovered: false,
    };
  },
  computed: {
    toggleChevronClass() {
      return this.expanded ? 'fa-chevron-up' : 'fa-chevron-down';
    },
    noteTimestampLink() {
      return this.noteId ? `#note_${this.noteId}` : undefined;
    },
    hasAuthor() {
      return this.author && Object.keys(this.author).length;
    },
    showGitlabTeamMemberBadge() {
      return this.author?.is_gitlab_employee;
    },
    authorLinkClasses() {
      return {
        hover: this.isUsernameLinkHovered,
        'text-underline': this.isUsernameLinkHovered,
        'author-name-link': true,
        'js-user-link': true,
      };
    },
    authorPath() {
      return this.author.path;
    },
    authorName() {
      return this.author.name;
    },
    authorUsername() {
      return this.author.username;
    },
    authorId() {
      return this.author.id;
    },
    authorStatus() {
      return this.author.status_tooltip_html;
    },
  },
  mounted() {
    // Temporarily remove `title` attribute from emoji when tooltip is open
    // Prevents duplicate tooltips (Bootstrap tooltip and browser title tooltip)
    if (this.hasAuthorStatusWithTooltip()) {
      const { authorStatus } = this.$refs;
      const emoji = authorStatus.querySelector('gl-emoji');
      const emojiTitle = emoji.getAttribute('title');

      this.handleAuthorStatusTooltipShow = () => emoji.removeAttribute('title');
      this.handleAuthorStatusTooltipHidden = () => emoji.setAttribute('title', emojiTitle);
      $(authorStatus).on('show.bs.tooltip', this.handleAuthorStatusTooltipShow);
      $(authorStatus).on('hidden.bs.tooltip', this.handleAuthorStatusTooltipHidden);
    }
  },
  beforeDestroy() {
    if (this.hasAuthorStatusWithTooltip()) {
      const { authorStatus } = this.$refs;

      $(authorStatus).off('show.bs.tooltip', this.handleAuthorStatusTooltipShow);
      $(authorStatus).off('hidden.bs.tooltip', this.handleAuthorStatusTooltipHidden);
    }
  },
  methods: {
    ...mapActions(['setTargetNoteHash']),
    handleToggle() {
      this.$emit('toggleHandler');
    },
    updateTargetNoteHash() {
      if (this.$store) {
        this.setTargetNoteHash(this.noteTimestampLink);
      }
    },
    handleUsernameMouseEnter() {
      this.$refs.authorNameLink.dispatchEvent(new Event('mouseenter'));

      this.isUsernameLinkHovered = true;
    },
    handleUsernameMouseLeave() {
      this.$refs.authorNameLink.dispatchEvent(new Event('mouseleave'));

      this.isUsernameLinkHovered = false;
    },
    hasAuthorStatusWithTooltip() {
      return this.$refs.authorStatus?.querySelector('.user-status-emoji:not([title=""])');
    },
  },
};
</script>

<template>
  <div class="note-header-info">
    <div v-if="includeToggle" ref="discussionActions" class="discussion-actions">
      <button
        class="note-action-button discussion-toggle-button js-vue-toggle-button"
        type="button"
        @click="handleToggle"
      >
        <i ref="chevronIcon" :class="toggleChevronClass" class="fa" aria-hidden="true"></i>
        {{ __('Toggle thread') }}
      </button>
    </div>
    <template v-if="hasAuthor">
      <a
        ref="authorNameLink"
        :href="authorPath"
        :class="authorLinkClasses"
        :data-user-id="authorId"
        :data-username="authorUsername"
      >
        <slot name="note-header-info"></slot>
        <span class="note-header-author-name bold">{{ authorName }}</span>
      </a>
      <span v-if="authorStatus" ref="authorStatus" v-html="authorStatus"></span>
      <span class="text-nowrap author-username">
        <a
          ref="authorUsernameLink"
          class="author-username-link"
          :href="authorPath"
          @mouseenter="handleUsernameMouseEnter"
          @mouseleave="handleUsernameMouseLeave"
          ><span class="note-headline-light">@{{ authorUsername }}</span>
        </a>
        <gitlab-team-member-badge v-if="showGitlabTeamMemberBadge" />
      </span>
    </template>
    <span v-else>{{ __('A deleted user') }}</span>
    <span class="note-headline-light note-headline-meta">
      <span class="system-note-message"> <slot></slot> </span>
      <template v-if="createdAt">
        <span ref="actionText" class="system-note-separator">
          <template v-if="actionText">{{ actionText }}</template>
        </span>
        <a
          v-if="noteTimestampLink"
          ref="noteTimestampLink"
          :href="noteTimestampLink"
          class="note-timestamp system-note-separator"
          @click="updateTargetNoteHash"
        >
          <time-ago-tooltip :time="createdAt" tooltip-placement="bottom" />
        </a>
        <time-ago-tooltip v-else ref="noteTimestamp" :time="createdAt" tooltip-placement="bottom" />
      </template>
      <slot name="extra-controls"></slot>
      <i
        v-if="showSpinner"
        ref="spinner"
        class="fa fa-spinner fa-spin editing-spinner"
        :aria-label="__('Comment is being updated')"
        aria-hidden="true"
      ></i>
    </span>
  </div>
</template>
