<script>
import { mapGetters, mapActions } from 'vuex';
import { n__ } from '~/locale';
import { camelCase } from 'lodash';
import DashboardFilter from './filter.vue';
import GlToggleVuex from '~/vue_shared/components/gl_toggle_vuex.vue';

export default {
  components: {
    DashboardFilter,
    GlToggleVuex,
  },
  props: {
    securityReportSummary: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    ...mapGetters('filters', ['visibleFilters']),
  },
  methods: {
    ...mapActions('filters', ['setFilter']),
    /**
     * This method lets us match some data coming from the API with values that are currently
     * hardcoded in the frontend.
     * We are considering moving the whole thing to the backend so that we can rely on a SSoT.
     * https://gitlab.com/gitlab-org/gitlab/-/issues/217373
     */
    getOptionEnrichedData(filter, option) {
      if (filter.id === 'report_type') {
        const { id: optionId } = option;
        const optionData = this.securityReportSummary[camelCase(optionId)];
        if (!optionData) {
          return null;
        }
        const { vulnerabilitiesCount, scannedResourcesCount } = optionData;
        const enrichedData = [];
        if (vulnerabilitiesCount !== undefined) {
          enrichedData.push(n__('%d vulnerability', '%d vulnerabilities', vulnerabilitiesCount));
        }
        if (scannedResourcesCount !== undefined) {
          enrichedData.push(n__('%d url scanned', '%d urls scanned', scannedResourcesCount));
        }
        return enrichedData.join(', ');
      }
      return null;
    },
  },
};
</script>

<template>
  <div class="dashboard-filters border-bottom bg-gray-light">
    <div class="row mx-0 p-2">
      <dashboard-filter
        v-for="filter in visibleFilters"
        :key="filter.id"
        class="col-sm-6 col-md-4 col-lg-2 p-2 js-filter"
        :class="`js-filter-${filter.id}`"
        :filter="filter"
        @setFilter="setFilter"
      >
        <template #default="{ option }">
          <span
            v-if="getOptionEnrichedData(filter, option)"
            class="gl-text-gray-500 gl-white-space-nowrap"
          >
            &nbsp;({{ getOptionEnrichedData(filter, option) }})
          </span>
        </template>
      </dashboard-filter>
      <div class="ml-lg-auto p-2">
        <strong>{{ s__('SecurityReports|Hide dismissed') }}</strong>
        <gl-toggle-vuex
          class="d-block mt-1 js-toggle"
          store-module="filters"
          state-property="hideDismissed"
          set-action="setToggleValue"
        />
      </div>
    </div>
  </div>
</template>
