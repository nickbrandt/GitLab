<script>
import Icon from '~/vue_shared/components/icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: { Icon, TimeAgoTooltip },
  props: {
    discussion: {
      type: Object,
      required: true,
    },
  },
  computed: {
    systemNote() {
      return this.discussion.notes.find(x => x.system === true);
    },
  },
};
</script>

<template>
  <li v-if="systemNote" class="card border-bottom system-note p-0">
    <div class="note-header-info mx-3 my-4">
      <div class="timeline-icon mr-0">
        <icon ref="icon" :name="systemNote.system_note_icon_name" />
      </div>

      <a
        :href="systemNote.author.path"
        class="js-user-link ml-3"
        :data-user-id="systemNote.author.id"
      >
        <strong ref="authorName" class="note-header-author-name">
          {{ systemNote.author.name }}
        </strong>
        <span
          v-if="systemNote.author.status_tooltip_html"
          ref="authorStatus"
          v-html="systemNote.author.status_tooltip_html"
        ></span>
        <span ref="authorUsername" class="note-headline-light">
          @{{ systemNote.author.username }}
        </span>
      </a>
      <span ref="stateChangeMessage" class="note-headline-light">
        {{ systemNote.note }}
        <time-ago-tooltip :time="systemNote.created_at" />
      </span>
    </div>
  </li>
</template>
