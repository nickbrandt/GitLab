<script>
export default {
  props: {
    epic: {
      type: Object,
      required: true,
    },
    currentGroupId: {
      type: Number,
      required: true,
    },
    timeframeString: {
      type: String,
      required: true,
    },
  },
  computed: {
    isEpicGroupDifferent() {
      return this.currentGroupId !== this.epic.groupId;
    },
  },
};
</script>

<template>
  <span class="epic-details-cell" data-qa-selector="epic_details_cell">
    <div class="epic-title">
      <a :href="epic.webUrl" :title="epic.title" class="epic-url">{{ epic.title }}</a>
    </div>
    <div class="epic-group-timeframe">
      <span v-if="isEpicGroupDifferent" :title="epic.groupFullName" class="epic-group"
        >{{ epic.groupName }} &middot;</span
      >
      <span class="epic-timeframe">{{ timeframeString }}</span>
    </div>
  </span>
</template>
