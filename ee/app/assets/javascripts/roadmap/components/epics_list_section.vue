<script>
import { mapState, mapActions } from 'vuex';
import VirtualList from 'vue-virtual-scroll-list';

import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import eventHub from '../event_hub';

import { EPIC_DETAILS_CELL_WIDTH, TIMELINE_CELL_MIN_WIDTH, EPIC_ITEM_HEIGHT } from '../constants';

import EpicItem from './epic_item.vue';

export default {
  EpicItem,
  epicItemHeight: EPIC_ITEM_HEIGHT,
  components: {
    VirtualList,
    EpicItem,
  },
  mixins: [glFeatureFlagsMixin()],
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
      offsetLeft: 0,
      emptyRowContainerStyles: {},
      showBottomShadow: false,
      roadmapShellEl: null,
    };
  },
  computed: {
    ...mapState(['bufferSize']),
    emptyRowContainerVisible() {
      return this.epics.length < this.bufferSize;
    },
    sectionContainerStyles() {
      return {
        width: `${EPIC_DETAILS_CELL_WIDTH + TIMELINE_CELL_MIN_WIDTH * this.timeframe.length}px`,
      };
    },
    shadowCellStyles() {
      return {
        left: `${this.offsetLeft}px`,
      };
    },
  },
  mounted() {
    eventHub.$on('epicsListScrolled', this.handleEpicsListScroll);
    this.initMounted();
  },
  beforeDestroy() {
    eventHub.$off('epicsListScrolled', this.handleEpicsListScroll);
  },
  methods: {
    ...mapActions(['setBufferSize']),
    initMounted() {
      this.roadmapShellEl = this.$root.$el && this.$root.$el.firstChild;
      this.setBufferSize(Math.ceil((window.innerHeight - this.$el.offsetTop) / EPIC_ITEM_HEIGHT));

      // Wait for component render to complete
      this.$nextTick(() => {
        this.offsetLeft = (this.$el.parentElement && this.$el.parentElement.offsetLeft) || 0;

        // We cannot scroll to the indicator immediately
        // on render as it will trigger scroll event leading
        // to timeline expand, so we wait for another render
        // cycle to complete.
        this.$nextTick(() => {
          this.scrollToTodayIndicator();
        });

        if (!Object.keys(this.emptyRowContainerStyles).length) {
          this.emptyRowContainerStyles = this.getEmptyRowContainerStyles();
        }
      });
    },
    getEmptyRowContainerStyles() {
      if (this.$refs.epicItems && this.$refs.epicItems.length) {
        return {
          height: `${this.$el.clientHeight -
            this.epics.length * this.$refs.epicItems[0].$el.clientHeight}px`,
        };
      }
      return {};
    },
    /**
     * Scroll timeframe to the right of the timeline
     * by half the column size
     */
    scrollToTodayIndicator() {
      if (this.$el.parentElement) this.$el.parentElement.scrollBy(TIMELINE_CELL_MIN_WIDTH / 2, 0);
    },
    handleEpicsListScroll({ scrollTop, clientHeight, scrollHeight }) {
      this.showBottomShadow = Math.ceil(scrollTop) + clientHeight < scrollHeight;
    },
    getEpicItemProps(index) {
      return {
        key: index,
        props: {
          epic: this.epics[index],
          presetType: this.presetType,
          timeframe: this.timeframe,
          currentGroupId: this.currentGroupId,
        },
      };
    },
  },
};
</script>

<template>
  <div :style="sectionContainerStyles" class="epics-list-section">
    <template v-if="glFeatures.roadmapBufferedRendering && !emptyRowContainerVisible">
      <virtual-list
        v-if="epics.length"
        :size="$options.epicItemHeight"
        :remain="bufferSize"
        :bench="bufferSize"
        :scrollelement="roadmapShellEl"
        :item="$options.EpicItem"
        :itemcount="epics.length"
        :itemprops="getEpicItemProps"
      />
    </template>
    <template v-else>
      <epic-item
        v-for="(epic, index) in epics"
        ref="epicItems"
        :key="index"
        :preset-type="presetType"
        :epic="epic"
        :timeframe="timeframe"
        :current-group-id="currentGroupId"
      />
    </template>
    <div
      v-if="emptyRowContainerVisible"
      :style="emptyRowContainerStyles"
      class="epics-list-item epics-list-item-empty clearfix"
    >
      <span class="epic-details-cell"></span>
      <span
        v-for="(timeframeItem, index) in timeframe"
        :key="index"
        class="epic-timeline-cell"
      ></span>
    </div>
    <div v-show="showBottomShadow" :style="shadowCellStyles" class="scroll-bottom-shadow"></div>
  </div>
</template>
