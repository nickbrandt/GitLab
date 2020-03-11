<script>
import { mapActions } from 'vuex';
import timeAgoTooltip from '../../vue_shared/components/time_ago_tooltip.vue';
import { GlIcon, GlSprintf } from '@gitlab/ui';
import { NOTEABLE_NOTE } from '../constants';

export default {
  components: {
    timeAgoTooltip,
    GlIcon,
    GlSprintf,
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
    noteType: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    toggleChevronClass() {
      return this.expanded ? 'fa-chevron-up' : 'fa-chevron-down';
    },
    noteTimestampLink() {
      return `#note_${this.noteId}`;
    },
    hasAuthor() {
      return this.author && Object.keys(this.author).length;
    },
    showGitLabEmployeeBadge() {
      return this.noteType === NOTEABLE_NOTE && this.hasAuthor && this.author.is_gitlab_employee;
    },
    noteHeadlineClasses() {
      const classes = ['note-headline-light', 'note-headline-meta', 'align-middle'];

      if (this.showGitLabEmployeeBadge) {
        classes.push('mr-1');
      }

      return classes;
    },
  },
  methods: {
    ...mapActions(['setTargetNoteHash']),
    handleToggle() {
      this.$emit('toggleHandler');
    },
    updateTargetNoteHash() {
      this.setTargetNoteHash(this.noteTimestampLink);
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
    <a
      v-if="hasAuthor"
      v-once
      :href="author.path"
      class="js-user-link align-middle"
      :data-user-id="author.id"
      :data-username="author.username"
    >
      <slot name="note-header-info"></slot>
      <span class="note-header-author-name bold">{{ author.name }}</span>
      <span v-if="author.status_tooltip_html" v-html="author.status_tooltip_html"></span>
      <span class="note-headline-light">@{{ author.username }}</span>
    </a>
    <span v-else>{{ __('A deleted user') }}</span>
    <span :class="noteHeadlineClasses">
      <span class="system-note-message"> <slot></slot> </span>
      <template v-if="createdAt">
        <span ref="actionText" class="system-note-separator">
          <template v-if="actionText">{{ actionText }}</template>
        </span>
        <a
          ref="noteTimestamp"
          :href="noteTimestampLink"
          class="note-timestamp system-note-separator"
          @click="updateTargetNoteHash"
        >
          <time-ago-tooltip :time="createdAt" tooltip-placement="bottom" />
        </a>
      </template>
      <slot name="extra-controls"></slot>
      <i
        class="fa fa-spinner fa-spin editing-spinner"
        :aria-label="__('Comment is being updated')"
        aria-hidden="true"
      ></i>
    </span>
    <span
      v-if="showGitLabEmployeeBadge"
      ref="gitLabEmployeeBadge"
      class="cgray-700 align-middlShoulde text-nowrap"
    >
      <gl-icon name="work" :size="16" class="align-middle" />
      <span class="align-middle">
        <gl-sprintf :message="__('GitLab')" />
      </span>
    </span>
  </div>
</template>
