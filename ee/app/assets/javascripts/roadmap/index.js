import Vue from 'vue';

import Translate from '~/vue_shared/translate';

import { parseBoolean } from '~/lib/utils/common_utils';
import { visitUrl, mergeUrlParams } from '~/lib/utils/url_utility';

import { PRESET_TYPES, EPIC_DETAILS_CELL_WIDTH } from './constants';

import { getTimeframeForPreset, getEpicsPathForPreset } from './utils/roadmap_utils';

import RoadmapStore from './store/roadmap_store';
import RoadmapService from './service/roadmap_service';

import roadmapApp from './components/app.vue';

Vue.use(Translate);

export default () => {
  const el = document.getElementById('js-roadmap');
  const presetButtonsContainer = document.querySelector('.js-btn-roadmap-presets');

  if (!el) {
    return false;
  }

  // This event handler is to be removed in 11.1 once
  // we allow user to save selected preset in db
  if (presetButtonsContainer) {
    presetButtonsContainer.addEventListener('click', e => {
      const presetType = e.target.querySelector('input[name="presetType"]').value;

      visitUrl(mergeUrlParams({ layout: presetType }, window.location.href));
    });
  }

  return new Vue({
    el,
    components: {
      roadmapApp,
    },
    data() {
      const supportedPresetTypes = Object.keys(PRESET_TYPES);
      const { dataset } = this.$options.el;
      const hasFiltersApplied = parseBoolean(dataset.hasFiltersApplied);
      const presetType =
        supportedPresetTypes.indexOf(dataset.presetType) > -1
          ? dataset.presetType
          : PRESET_TYPES.MONTHS;
      const filterQueryString = window.location.search.substring(1);
      const timeframe = getTimeframeForPreset(
        presetType,
        window.innerWidth - el.offsetLeft - EPIC_DETAILS_CELL_WIDTH,
      );
      const initialEpicsPath = getEpicsPathForPreset({
        basePath: dataset.epicsPath,
        epicsState: dataset.epicsState,
        filterQueryString,
        presetType,
        timeframe,
      });

      const store = new RoadmapStore({
        groupId: parseInt(dataset.groupId, 0),
        sortedBy: dataset.sortedBy,
        timeframe,
        presetType,
      });

      const service = new RoadmapService({
        initialEpicsPath,
        filterQueryString,
        basePath: dataset.epicsPath,
        epicsState: dataset.epicsState,
      });

      return {
        store,
        service,
        presetType,
        hasFiltersApplied,
        epicsState: dataset.epicsState,
        newEpicEndpoint: dataset.newEpicEndpoint,
        emptyStateIllustrationPath: dataset.emptyStateIllustration,
      };
    },
    render(createElement) {
      return createElement('roadmap-app', {
        props: {
          store: this.store,
          service: this.service,
          presetType: this.presetType,
          hasFiltersApplied: this.hasFiltersApplied,
          epicsState: this.epicsState,
          newEpicEndpoint: this.newEpicEndpoint,
          emptyStateIllustrationPath: this.emptyStateIllustrationPath,
        },
      });
    },
  });
};
