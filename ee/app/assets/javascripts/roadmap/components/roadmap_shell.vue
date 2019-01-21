<script>
import bp from '~/breakpoints';
import { isInViewport } from '~/lib/utils/common_utils';
import { SCROLL_BAR_SIZE, EPIC_ITEM_HEIGHT, SHELL_MIN_WIDTH, EXTEND_AS } from '../constants';
import eventHub from '../event_hub';

import epicsListSection from './epics_list_section.vue';
import roadmapTimelineSection from './roadmap_timeline_section.vue';

export default {
  components: {
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
      const width =
        bp.windowWidth() > SHELL_MIN_WIDTH
          ? this.shellWidth + this.getWidthOffset()
          : this.shellWidth;

      return {
        width: `${width}px`,
        height: `${this.shellHeight}px`,
      };
    },
  },
  mounted() {
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
        this.shellWidth = this.$el.parentElement.clientWidth + this.getWidthOffset();

        this.timeframeStartOffset = this.$refs.roadmapTimeline.$el
          .querySelector('.timeline-header-item')
          .querySelector('.item-sublabel .sublabel-value:first-child')
          .getBoundingClientRect().left;
      }
    });
  },
  methods: {
    getWidthOffset() {
      return this.noScroll ? 0 : SCROLL_BAR_SIZE;
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

      this.noScroll = this.shellHeight > EPIC_ITEM_HEIGHT * (this.epics.length + 1);
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
