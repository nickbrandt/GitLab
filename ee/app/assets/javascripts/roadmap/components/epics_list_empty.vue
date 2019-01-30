<script>
import { s__, sprintf } from '~/locale';
import { dateInWords } from '~/lib/utils/datetime_utility';

import { PRESET_TYPES, emptyStateDefault, emptyStateWithFilters } from '../constants';

import initEpicCreate from '../../epic/epic_bundle';

export default {
  props: {
    presetType: {
      type: String,
      required: true,
    },
    timeframeStart: {
      type: [Date, Object],
      required: true,
    },
    timeframeEnd: {
      type: [Date, Object],
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
  computed: {
    timeframeRange() {
      let startDate;
      let endDate;

      if (this.presetType === PRESET_TYPES.QUARTERS) {
        const quarterStart = this.timeframeStart.range[0];
        const quarterEnd = this.timeframeEnd.range[2];
        startDate = dateInWords(
          quarterStart,
          true,
          quarterStart.getFullYear() === quarterEnd.getFullYear(),
        );
        endDate = dateInWords(quarterEnd, true);
      } else if (this.presetType === PRESET_TYPES.MONTHS) {
        startDate = dateInWords(
          this.timeframeStart,
          true,
          this.timeframeStart.getFullYear() === this.timeframeEnd.getFullYear(),
        );
        endDate = dateInWords(this.timeframeEnd, true);
      } else if (this.presetType === PRESET_TYPES.WEEKS) {
        const end = new Date(this.timeframeEnd.getTime());
        end.setDate(end.getDate() + 6);

        startDate = dateInWords(
          this.timeframeStart,
          true,
          this.timeframeStart.getFullYear() === end.getFullYear(),
        );
        endDate = dateInWords(end, true);
      }

      return {
        startDate,
        endDate,
      };
    },
    message() {
      if (this.hasFiltersApplied) {
        return s__('GroupRoadmap|Sorry, no epics matched your search');
      }
      return s__('GroupRoadmap|The roadmap shows the progress of your epics along a timeline');
    },
    subMessage() {
      if (this.hasFiltersApplied) {
        return sprintf(emptyStateWithFilters, {
          startDate: this.timeframeRange.startDate,
          endDate: this.timeframeRange.endDate,
        });
      }
      return sprintf(emptyStateDefault, {
        startDate: this.timeframeRange.startDate,
        endDate: this.timeframeRange.endDate,
      });
    },
  },
  mounted() {
    // If filters are not applied and yet user
    // is seeing empty state, we need to show
    // `New epic` button, so boot-up Epic app
    // in create mode.
    if (!this.hasFiltersApplied) {
      initEpicCreate(true);
    }
  },
};
</script>

<template>
  <div class="row empty-state">
    <div class="col-12">
      <div class="svg-content"><img :src="emptyStateIllustrationPath" /></div>
    </div>
    <div class="col-12">
      <div class="text-content">
        <h4>{{ message }}</h4>
        <p v-html="subMessage"></p>
        <div class="text-center">
          <div
            v-if="!hasFiltersApplied"
            id="epic-create-root"
            :data-endpoint="newEpicEndpoint"
          ></div>
          <a :title="__('List')" :href="newEpicEndpoint" class="btn btn-default">
            <span>{{ s__('View epics list') }}</span>
          </a>
        </div>
      </div>
    </div>
  </div>
</template>
