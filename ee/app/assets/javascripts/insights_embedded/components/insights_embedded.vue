<script>
import { mapActions, mapState } from 'vuex';
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import InsightsEmbeddedPage from './insights_embedded_page.vue';
import InsightsConfigWarning from '../../insights/components/insights_config_warning.vue';

export default {
  components: {
    GlAlert,
    GlLoadingIcon,
    InsightsEmbeddedPage,
    InsightsConfigWarning,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    queryEndpoint: {
      type: String,
      required: true,
    },
    notice: {
      type: String,
      default: '',
      required: false,
    },
  },
  computed: {
    ...mapState('insights', ['configData', 'configLoading', 'pageLoading']),
    configPresent() {
      return !this.configLoading && this.configData != null;
    },
    issuableType() {
      return this.$route.query.issuableType;
    },
    specifiedChartIndex() {
      return Number(this.$route.query.index);
    },
    chartConfig() {
      return this.configData[this.issuableType]?.charts[this.specifiedChartIndex];
    },
    chartNotFound() {
      return this.configPresent && !this.chartConfig;
    },
  },
  mounted() {
    this.fetchConfigData(this.endpoint);
  },
  methods: {
    ...mapActions('insights', ['fetchConfigData']),
    validIssuableType() {
      return this.issuableType && this.validTab(this.issuableType);
    },
    validTab(tab) {
      return Object.prototype.hasOwnProperty.call(this.configData, tab);
    },
  },
};
</script>
<template>
  <div class="insights-container gl-mt-3">
    <div v-if="configLoading" class="insights-config-loading text-center">
      <gl-loading-icon :inline="true" size="lg" />
    </div>
    <div v-else-if="chartNotFound" class="insights-wrapper">
      <gl-alert>
        {{ s__('Insights|The chart specified with the given query was not found.') }}
      </gl-alert>
    </div>
    <div v-else-if="chartConfig" class="insights-wrapper">
      <gl-alert v-if="notice != ''">
        {{ notice }}
      </gl-alert>
      <insights-embedded-page :query-endpoint="queryEndpoint" :chart-config="chartConfig" />
    </div>
    <insights-config-warning
      v-else
      :title="__('Invalid Insights config file detected')"
      :summary="
        __(
          'Please check the configuration file to ensure that it is available and the YAML is valid',
        )
      "
      image="illustrations/monitoring/getting_started.svg"
    />
  </div>
</template>
