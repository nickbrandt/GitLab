<script>
import { delay } from 'lodash';

import epicItemDetails from './epic_item_details.vue';
import epicItemTimeline from './epic_item_timeline.vue';

import CommonMixin from '../mixins/common_mixin';

import { EPIC_HIGHLIGHT_REMOVE_AFTER } from '../constants';

export default {
  components: {
    epicItemDetails,
    epicItemTimeline,
  },
  mixins: [CommonMixin],
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
          delay(() => {
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
      :timeframe-string="timeframeString(epic)"
    />
    <epic-item-timeline
      v-for="(timeframeItem, index) in timeframe"
      :key="index"
      :preset-type="presetType"
      :timeframe="timeframe"
      :timeframe-item="timeframeItem"
      :epic="epic"
      :client-width="clientWidth"
    />
  </div>
</template>
