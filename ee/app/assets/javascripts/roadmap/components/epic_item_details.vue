<script>
import { s__, sprintf } from '~/locale';
import { dateInWords } from '~/lib/utils/datetime_utility';

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
  },
  computed: {
    isEpicGroupDifferent() {
      return this.currentGroupId !== this.epic.groupId;
    },
    /**
     * In case Epic start date is out of range
     * we need to use original date instead of proxy date
     */
    startDate() {
      if (this.epic.startDateOutOfRange) {
        return this.epic.originalStartDate;
      }

      return this.epic.startDate;
    },
    /**
     * In case Epic end date is out of range
     * we need to use original date instead of proxy date
     */
    endDate() {
      if (this.epic.endDateOutOfRange) {
        return this.epic.originalEndDate;
      }
      return this.epic.endDate;
    },
    /**
     * Compose timeframe string to show on UI
     * based on start and end date availability
     */
    timeframeString() {
      if (this.epic.startDateUndefined) {
        return sprintf(s__('GroupRoadmap|Until %{dateWord}'), {
          dateWord: dateInWords(this.endDate, true),
        });
      } else if (this.epic.endDateUndefined) {
        return sprintf(s__('GroupRoadmap|From %{dateWord}'), {
          dateWord: dateInWords(this.startDate, true),
        });
      }

      // In case both start and end date fall in same year
      // We should hide year from start date
      const startDateInWords = dateInWords(
        this.startDate,
        true,
        this.startDate.getFullYear() === this.endDate.getFullYear(),
      );

      const endDateInWords = dateInWords(this.endDate, true);
      return sprintf(s__('GroupRoadmap|%{startDateInWords} &ndash; %{endDateInWords}'), {
        startDateInWords,
        endDateInWords,
      });
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
      <span class="epic-timeframe" v-html="timeframeString"></span>
    </div>
  </span>
</template>
