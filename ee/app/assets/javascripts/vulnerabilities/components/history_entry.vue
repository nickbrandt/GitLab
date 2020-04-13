<script>
import EventItem from 'ee/vue_shared/security_reports/components/event_item.vue';

export default {
  components: { EventItem },
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
    <event-item
      :id="systemNote.id"
      :author="systemNote.author"
      :created-at="systemNote.created_at"
      :icon-name="systemNote.system_note_icon_name"
      icon-class="timeline-icon m-0"
      class="m-3"
    >
      <template #header-message>{{ systemNote.note }}</template>
    </event-item>
  </li>
</template>
