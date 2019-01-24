<script>
import { GlSkeletonLoading } from '@gitlab/ui';

import { isInViewport } from '~/lib/utils/common_utils';
import { SCROLL_BAR_SIZE, EPIC_ITEM_HEIGHT, EXTEND_AS } from '../constants';
import eventHub from '../event_hub';

import epicsListSection from './epics_list_section.vue';
import roadmapTimelineSection from './roadmap_timeline_section.vue';

export default {
  components: {
    GlSkeletonLoading,
    epicsListSection,
    roadmapTimelineSection,
  },
  props: {
    presetType: {
      type: String,
      required: true,
    },
    epics: {
      type: Array,
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
  },
  data() {
    return {
      shellWidth: 0,
      shellHeight: 0,
      noScroll: false,
      timeframeStartOffset: 0,
    };
  },
  computed: {
    containerStyles() {
      return {
        width: `${this.shellWidth}px`,
        height: `${this.shellHeight}px`,
      };
    },
  },
  watch: {
    /**
     * Watcher to monitor whether epics list is long enough
     * to allow vertical list scrolling.
     *
     * In case of scrollable list, we don't want vertical scrollbar
     * to be visible, so we mask the scrollbar by increasing shell
     * width past the scrollbar size.
     */
    noScroll(value) {
      if (this.$el.parentElement) {
        this.shellWidth = this.getShellWidth(value);
      }
    },
  },
  mounted() {
    eventHub.$on('refreshTimeline', this.handleEpicsListRendered);
    this.$nextTick(() => {
      // Client width at the time of component mount will not
      // provide accurate size of viewport until child contents are
      // actually loaded and rendered into the DOM, hence
      // we wait for nextTick which ensures DOM update has completed
      // before setting shellWidth
      // see https://vuejs.org/v2/api/#Vue-nextTick
      if (this.$el.parentElement) {
        this.shellHeight = window.innerHeight - this.$el.offsetTop;
        this.noScroll = this.shellHeight > EPIC_ITEM_HEIGHT * (this.epics.length + 1);
        this.shellWidth = this.getShellWidth(this.noScroll);

        // We're guarding this as in tests, `roadmapTimeline`
        // is not ready when this line is executed.
        if (this.$refs.roadmapTimeline) {
          this.timeframeStartOffset = this.$refs.roadmapTimeline.$el
            .querySelector('.timeline-header-item')
            .querySelector('.item-sublabel .sublabel-value:first-child')
            .getBoundingClientRect().left;
        }
      }
    });
  },
  beforeDestroy() {
    eventHub.$off('refreshTimeline', this.handleEpicsListRendered);
  },
  methods: {
    getShellWidth(noScroll) {
      return this.$el.parentElement.clientWidth + (noScroll ? 0 : SCROLL_BAR_SIZE);
    },
    handleEpicsListRendered() {
      this.noScroll = this.shellHeight > EPIC_ITEM_HEIGHT * (this.epics.length + 1);
    },
    handleScroll() {
      const { scrollTop, scrollLeft, clientHeight, scrollHeight } = this.$el;
      const timelineEdgeStartEl = this.$refs.roadmapTimeline.$el
        .querySelector('.timeline-header-item')
        .querySelector('.item-sublabel .sublabel-value:first-child');
      const timelineEdgeEndEl = this.$refs.roadmapTimeline.$el
        .querySelector('.timeline-header-item:last-child')
        .querySelector('.item-sublabel .sublabel-value:last-child');

      // If timeline was scrolled to start
      if (isInViewport(timelineEdgeStartEl, { left: this.timeframeStartOffset })) {
        this.$emit('onScrollToStart', this.$refs.roadmapTimeline.$el, EXTEND_AS.PREPEND);
      } else if (isInViewport(timelineEdgeEndEl)) {
        // If timeline was scrolled to end
        this.$emit('onScrollToEnd', this.$refs.roadmapTimeline.$el, EXTEND_AS.APPEND);
      }

      eventHub.$emit('epicsListScrolled', { scrollTop, scrollLeft, clientHeight, scrollHeight });
    },
  },
};
</script>

<template>
  <div
    :class="{ 'prevent-vertical-scroll': noScroll }"
    :style="containerStyles"
    class="roadmap-shell"
    @scroll="handleScroll"
  >
    <roadmap-timeline-section
      ref="roadmapTimeline"
      :preset-type="presetType"
      :epics="epics"
      :timeframe="timeframe"
      :shell-width="shellWidth"
      :list-scrollable="!noScroll"
    />
    <div v-if="!epics.length" class="skeleton-loader js-skeleton-loader">
      <div v-for="n in 10" :key="n" class="mt-2">
        <gl-skeleton-loading :lines="2" />
      </div>
    </div>
    <epics-list-section
      :preset-type="presetType"
      :epics="epics"
      :timeframe="timeframe"
      :shell-width="shellWidth"
      :current-group-id="currentGroupId"
      :list-scrollable="!noScroll"
    />
  </div>
</template>
