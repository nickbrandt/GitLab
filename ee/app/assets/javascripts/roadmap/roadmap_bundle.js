import Vue from 'vue';
import { mapActions } from 'vuex';

import Translate from '~/vue_shared/translate';

import EpicItem from './components/epic_item.vue';
import EpicItemContainer from './components/epic_item_container.vue';

import {
  parseBoolean,
  urlParamsToObject,
  convertObjectPropsToCamelCase,
} from '~/lib/utils/common_utils';
import { visitUrl, mergeUrlParams } from '~/lib/utils/url_utility';

import { PRESET_TYPES, EPIC_DETAILS_CELL_WIDTH } from './constants';

import { getEpicsPathForPreset, getTimeframeForPreset } from './utils/roadmap_utils';

import createStore from './store';

import roadmapApp from './components/roadmap_app.vue';

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

  Vue.component('epic-item', EpicItem);
  Vue.component('epic-item-container', EpicItemContainer);

  return new Vue({
    el,
    store: createStore(),
    components: {
      roadmapApp,
    },
    data() {
      const supportedPresetTypes = Object.keys(PRESET_TYPES);
      const { dataset } = this.$options.el;
      const presetType =
        supportedPresetTypes.indexOf(dataset.presetType) > -1
          ? dataset.presetType
          : PRESET_TYPES.MONTHS;
      const filterQueryString = window.location.search.substring(1);
      const filterParams = Object.assign(
        convertObjectPropsToCamelCase(urlParamsToObject(filterQueryString), {
          dropKeys: ['scope', 'utf8', 'state', 'sort', 'layout'], // These keys are unsupported/unnecessary
        }),
      );
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

      return {
        emptyStateIllustrationPath: dataset.emptyStateIllustration,
        hasFiltersApplied: parseBoolean(dataset.hasFiltersApplied),
        defaultInnerHeight: Number(dataset.innerHeight),
        isChildEpics: parseBoolean(dataset.childEpics),
        currentGroupId: parseInt(dataset.groupId, 0),
        basePath: dataset.epicsPath,
        fullPath: dataset.fullPath,
        epicIid: dataset.iid,
        newEpicEndpoint: dataset.newEpicEndpoint,
        epicsState: dataset.epicsState,
        sortedBy: dataset.sortedBy,
        filterQueryString,
        initialEpicsPath,
        filterParams,
        presetType,
        timeframe,
      };
    },
    created() {
      this.setInitialData({
        currentGroupId: this.currentGroupId,
        fullPath: this.fullPath,
        epicIid: this.epicIid,
        sortedBy: this.sortedBy,
        presetType: this.presetType,
        epicsState: this.epicsState,
        timeframe: this.timeframe,
        basePath: this.basePath,
        filterQueryString: this.filterQueryString,
        filterParams: this.filterParams,
        initialEpicsPath: this.initialEpicsPath,
        defaultInnerHeight: this.defaultInnerHeight,
        isChildEpics: this.isChildEpics,
      });
    },
    methods: {
      ...mapActions(['setInitialData']),
    },
    render(createElement) {
      return createElement('roadmap-app', {
        props: {
          store: this.store,
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
