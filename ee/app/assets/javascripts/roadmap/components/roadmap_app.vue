<script>
import { mapState, mapActions } from 'vuex';

import epicsListEmpty from './epics_list_empty.vue';
import roadmapShell from './roadmap_shell.vue';
import eventHub from '../event_hub';

import { EXTEND_AS } from '../constants';

export default {
  components: {
    epicsListEmpty,
    roadmapShell,
  },
  props: {
    presetType: {
      type: String,
      required: true,
    },
    hasFiltersApplied: {
      type: Boolean,
      required: true,
    },
    newEpicEndpoint: {
      type: String,
      required: true,
    },
    emptyStateIllustrationPath: {
      type: String,
      required: true,
    },
  },
  data() {
    const roadmapGraphQL = gon.features && gon.features.roadmapGraphql;
    return {
      // TODO
      // Remove these method alias and call actual
      // method once feature flag is removed.
      fetchEpicsFn: roadmapGraphQL ? this.fetchEpicsGQL : this.fetchEpics,
      fetchEpicsForTimeframeFn: roadmapGraphQL
        ? this.fetchEpicsForTimeframeGQL
        : this.fetchEpicsForTimeframe,
    };
  },
  computed: {
    ...mapState([
      'currentGroupId',
      'epics',
      'timeframe',
      'extendedTimeframe',
      'windowResizeInProgress',
      'epicsFetchInProgress',
      'epicsFetchForTimeframeInProgress',
      'epicsFetchResultEmpty',
      'epicsFetchFailure',
      'isChildEpics',
    ]),
    timeframeStart() {
      return this.timeframe[0];
    },
    timeframeEnd() {
      const last = this.timeframe.length - 1;
      return this.timeframe[last];
    },
    showRoadmap() {
      return (
        !this.windowResizeInProgress &&
        !this.epicsFetchFailure &&
        !this.epicsFetchInProgress &&
        !this.epicsFetchResultEmpty
      );
    },
  },
  mounted() {
    this.fetchEpicsFn();
  },
  methods: {
    ...mapActions([
      'setWindowResizeInProgress',
      'fetchEpics',
      'fetchEpicsGQL',
      'fetchEpicsForTimeframe',
      'fetchEpicsForTimeframeGQL',
      'extendTimeframe',
      'refreshEpicDates',
    ]),
    /**
     * Once timeline is expanded (either with prepend or append)
     * We need performing following actions;
     *
     * 1. Reset start and end edges of the timeline for
     *    infinite scrolling to continue further.
     * 2. Re-render timeline bars to account for
     *    updated timeframe.
     * 3. In case of prepending timeframe,
     *    reset scroll-position (due to DOM prepend).
     */
    processExtendedTimeline({ extendType = EXTEND_AS.PREPEND, roadmapTimelineEl, itemsCount = 0 }) {
      // Re-render timeline bars with updated timeline
      eventHub.$emit('refreshTimeline', {
        todayBarReady: extendType === EXTEND_AS.PREPEND,
      });

      if (extendType === EXTEND_AS.PREPEND) {
        // When DOM is prepended with elements
        // we compensate the scrolling for added elements' width
        roadmapTimelineEl.parentElement.scrollBy(
          roadmapTimelineEl.querySelector('.timeline-header-item').clientWidth * itemsCount,
          0,
        );
      }
    },
    handleScrollToExtend(roadmapTimelineEl, extendType = EXTEND_AS.PREPEND) {
      this.extendTimeframe({ extendAs: extendType });
      this.refreshEpicDates();

      this.$nextTick(() => {
        this.fetchEpicsForTimeframeFn({
          timeframe: this.extendedTimeframe,
        })
          .then(() => {
            this.$nextTick(() => {
              // Re-render timeline bars with updated timeline
              this.processExtendedTimeline({
                itemsCount: this.extendedTimeframe ? this.extendedTimeframe.length : 0,
                extendType,
                roadmapTimelineEl,
              });
            });
          })
          .catch(() => {});
      });
    },
  },
};
</script>

<template>
  <div :class="{ 'overflow-reset': epicsFetchResultEmpty }" class="roadmap-container">
    <roadmap-shell
      v-if="showRoadmap"
      :preset-type="presetType"
      :epics="epics"
      :timeframe="timeframe"
      :current-group-id="currentGroupId"
      @onScrollToStart="handleScrollToExtend"
      @onScrollToEnd="handleScrollToExtend"
    />
    <epics-list-empty
      v-if="epicsFetchResultEmpty"
      :preset-type="presetType"
      :timeframe-start="timeframeStart"
      :timeframe-end="timeframeEnd"
      :has-filters-applied="hasFiltersApplied"
      :new-epic-endpoint="newEpicEndpoint"
      :empty-state-illustration-path="emptyStateIllustrationPath"
      :is-child-epics="isChildEpics"
    />
  </div>
</template>
