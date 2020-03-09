<script>
import _ from 'underscore';
import { s__, sprintf } from '~/locale';
import { dateInWords } from '~/lib/utils/datetime_utility';

import epicItemDetails from './epic_item_details.vue';
import epicItemTimeline from './epic_item_timeline.vue';

import { EPIC_HIGHLIGHT_REMOVE_AFTER } from '../constants';

export default {
  components: {
    epicItemDetails,
    epicItemTimeline,
  },
  props: {
    presetType: {
      type: String,
      required: true,
    },
    epic: {
      type: Object,
      required: true,
    },
    timeframe: {
      type: Array,
      required: true,
    },
    currentGroupId: {
      type: Number,
      required: true,
    },
    clientWidth: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
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
        return sprintf(s__('GroupRoadmap|No start date – %{dateWord}'), {
          dateWord: dateInWords(this.endDate, true),
        });
      } else if (this.epic.endDateUndefined) {
        return sprintf(s__('GroupRoadmap|%{dateWord} – No end date'), {
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
      return sprintf(s__('GroupRoadmap|%{startDateInWords} – %{endDateInWords}'), {
        startDateInWords,
        endDateInWords,
      });
    },
  },
  updated() {
    this.removeHighlight();
  },
  methods: {
    /**
     * When new epics are added to the list on
     * timeline scroll, we set `newEpic` flag
     * as true and then use it in template
     * to set `newly-added-epic` class for
     * highlighting epic using CSS animations
     *
     * Once animation is complete, we need to
     * remove the flag so that animation is not
     * replayed when list is re-rendered.
     */
    removeHighlight() {
      if (this.epic.newEpic) {
        this.$nextTick(() => {
          _.delay(() => {
            this.epic.newEpic = false;
          }, EPIC_HIGHLIGHT_REMOVE_AFTER);
        });
      }
    },
  },
};
</script>

<template>
  <div :class="{ 'newly-added-epic': epic.newEpic }" class="epics-list-item clearfix">
    <epic-item-details
      :epic="epic"
      :current-group-id="currentGroupId"
      :timeframe-string="timeframeString"
    />
    <epic-item-timeline
      v-for="(timeframeItem, index) in timeframe"
      :key="index"
      :preset-type="presetType"
      :timeframe="timeframe"
      :timeframe-item="timeframeItem"
      :epic="epic"
      :timeframe-string="timeframeString"
      :client-width="clientWidth"
    />
  </div>
</template>
