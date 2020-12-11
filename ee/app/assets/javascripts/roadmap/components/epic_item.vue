<script>
import { delay } from 'lodash';

import RoadmapItem from './roadmap_item.vue';
import EpicItemDetails from './epic_item_details.vue';
import RoadmapTimelineGrid from './roadmap_timeline_grid.vue';
import EpicItemTimeline from './epic_item_timeline.vue';

import { EPIC_ITEM_HEIGHT, EPIC_HIGHLIGHT_REMOVE_AFTER } from '../constants';

export default {
  epicItemHeight: EPIC_ITEM_HEIGHT,
  components: {
    RoadmapItem,
    EpicItemDetails,
    RoadmapTimelineGrid,
    EpicItemTimeline,
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
    childLevel: {
      type: Number,
      required: true,
    },
    childrenEpics: {
      type: Object,
      required: true,
    },
    childrenFlags: {
      type: Object,
      required: true,
    },
    hasFiltersApplied: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    isChildrenEmpty() {
      return this.childrenEpics[this.epic.id] && this.childrenEpics[this.epic.id].length === 0;
    },
    hasChildrenToShow() {
      return this.childrenFlags[this.epic.id].itemExpanded && this.childrenEpics[this.epic.id];
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
  <div class="epic-item-container">
    <roadmap-item
      :preset-type="presetType"
      :item="epic"
      :timeframe="timeframe"
      :class="{ 'newly-added-epic': epic.newEpic }"
      class="epics-list-item gl-relative clearfix"
    >
      <template #item-details="{timeframeString}">
        <epic-item-details
          :epic="epic"
          :current-group-id="currentGroupId"
          :timeframe-string="timeframeString"
          :child-level="childLevel"
          :children-flags="childrenFlags"
          :has-filters-applied="hasFiltersApplied"
          :is-children-empty="isChildrenEmpty"
        />
      </template>
      <template>
        <roadmap-timeline-grid
          :preset-type="presetType"
          :timeframe="timeframe"
          :height="$options.epicItemHeight"
        />
      </template>
      <template #timeline-bar="{timeframeString, timelineBarStyle}">
        <epic-item-timeline
          :epic="epic"
          :timeframe-string="timeframeString"
          :timeline-bar-style="timelineBarStyle"
          :client-width="clientWidth"
        />
      </template>
    </roadmap-item>

    <epic-item-container
      v-if="hasChildrenToShow"
      :preset-type="presetType"
      :timeframe="timeframe"
      :current-group-id="currentGroupId"
      :client-width="clientWidth"
      :children="childrenEpics[epic.id] || []"
      :child-level="childLevel + 1"
      :children-epics="childrenEpics"
      :children-flags="childrenFlags"
      :has-filters-applied="hasFiltersApplied"
    />
  </div>
</template>
