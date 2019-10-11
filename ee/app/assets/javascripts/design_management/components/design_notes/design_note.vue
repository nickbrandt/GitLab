<script>
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    UserAvatarLink,
    TimelineEntryItem,
    TimeAgoTooltip,
  },
  props: {
    note: {
      type: Object,
      required: true,
    },
  },
  computed: {
    author() {
      return this.note.author;
    },
  },
};
</script>

<template>
  <timeline-entry-item class="design-note note-form">
    <user-avatar-link
      :link-href="author.webUrl"
      :img-src="author.avatarUrl"
      :img-alt="author.username"
      :img-size="40"
    />
    <a
      v-once
      :href="author.webUrl"
      class="js-user-link"
      :data-user-id="author.id"
      :data-username="author.username"
    >
      <span class="note-header-author-name bold">{{ author.name }}</span>
      <span v-if="author.status_tooltip_html" v-html="author.status_tooltip_html"></span>
      <span class="note-headline-light">@{{ author.username }}</span>
    </a>
    <span class="note-headline-light note-headline-meta">
      <span class="system-note-message"> <slot></slot> </span>
      <template v-if="note.createdAt">
        <span class="system-note-separator"></span>
        <span class="note-timestamp system-note-separator">
          <time-ago-tooltip :time="note.createdAt" tooltip-placement="bottom" />
        </span>
      </template>
    </span>
    <div class="note-text md" data-qa-selector="note_content" v-html="note.bodyHtml"></div>
  </timeline-entry-item>
</template>
