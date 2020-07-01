<script>
import Vue from 'vue';
import { GlForm, GlFormTextarea, GlFormGroup, GlButton } from '@gitlab/ui';
import createFlash from '~/flash';

import DateTimePicker from '~/vue_shared/components/date_time_picker/date_time_picker.vue';
import DashboardPanel from '../components/dashboard_panel.vue';
import { timeRanges } from '~/vue_shared/constants';
import { metricStates } from '../constants';

import { normalizeQueryResponseData } from '../stores/utils';
import { prometheusMetricQueryParams, getPrometheusQueryData } from '../stores/actions';

/**
 * This component is presented as a separate vue router "page"
 * to express this should be a separate page.
 *
 * Additionally, several query parameters should feed this page:
 * - time range
 * - yml (which syncs with forms `ymlInput`)
 * - ... any other knob we add to this page!
 */

/**
 * These methods will have to move to a low-level
 * service layer, or somehow integrated to Vuex.
 * 
 * Questions:
 * - Should we add this to VueX? My initial impulse is no,
 *   all the state can be preserved in the URL params.
 */

const service = {
  convertPanelYmlDefinitionToJson: ymlInput => {
    return new Promise((resolve, reject) => {
      // Here we would sent a request to the backend
      // /metrics/transform-panel-yml-to-json?yml=...
      setTimeout(() => {
        try {
          // It worked
          resolve(JSON.parse(ymlInput));
        } catch {
          reject();
        }
      }, 500);
    });
  },
  getPrometheusResults: (url, timeRange) => {
    const params = prometheusMetricQueryParams(timeRange);

    return getPrometheusQueryData(url, params).then(data => {
      return normalizeQueryResponseData(data);
    });
  },
};

/**
 * This component logic should be split in around 3 others:
 *
 * - Page
 * - Builder
 * - Form
 *   - Form can evolve to support more fields
 */
export default {
  components: {
    GlForm,
    GlFormTextarea,
    GlFormGroup,
    GlButton,

    DateTimePicker,
    DashboardPanel,
  },
  props: {
    dashboardProps: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      timeRange: timeRanges[0],
      graphData: null,
      form: {
        submitDisabled: false,
        ymlInput: `{
  "title": "Memory Usage (Total)",
  "type": "area-chart",
  "xLabel": "",
  "y_label": "Total Memory Used (GB)",
  "yAxis": {
    "name": "Total Memory Used (GB)",
    "format": "engineering",
    "precision": 2
  },
  "xAxis": {
    "name": ""
  },
  "links": [],
  "metrics": [
    {
      "label": "Total (GB)",
      "unit": "GB",
      "queryRange": null,
      "prometheusEndpointPath": "/root/autodevops-deploy/-/environments/29/prometheus/api/v1/query_range?query=avg%28sum%28container_memory_usage_bytes%7Bcontainer_name%21%3D%22POD%22%2Cpod_name%3D~%22%5E%7B%7Bci_environment_slug%7D%7D-%28.%2A%29%22%2Cnamespace%3D%22%7B%7Bkube_namespace%7D%7D%22%7D%29+by+%28job%29%29+without+%28job%29++%2F1024%2F1024%2F1024"
    }
  ]
}`,
      },
    };
  },
  methods: {
    onSubmit() {
      this.form.submitDisabled = true;
      // eslint-disable-next-line promise/catch-or-return
      this.fetchParsedPanel().finally(() => {
        this.form.submitDisabled = false;
      });
    },

    fetchParsedPanel() {
      // eslint-disable-next-line promise/catch-or-return
      return service
        .convertPanelYmlDefinitionToJson(this.form.ymlInput)
        .catch(() => {
          createFlash('Parsing input failed! Please try again.');
        })
        .then(graphData => {
          this.graphData = graphData;
          return this.fetchMetricsData();
        });
    },

    fetchMetricsData() {
      const { metrics } = this.graphData;
      if (!metrics) {
        return Promise.resolve();
      }

      const promises = [];
      metrics.forEach(metric => {
        Vue.set(metric, 'loading', true);
        Vue.set(metric, 'result', null);
        Vue.set(metric, 'state', metricStates.LOADING);

        // eslint-disable-next-line promise/catch-or-return
        const promise = service
          .getPrometheusResults(metric.prometheusEndpointPath, this.timeRange)
          .then(result => {
            Vue.set(metric, 'loading', false);
            Vue.set(metric, 'result', result);
            Vue.set(metric, 'state', metricStates.OK);
          });

        promises.push(promise);
      });

      this.graphData = {
        metrics,
        ...this.graphData,
      };

      return Promise.all(promises);
    },
  },
  timeRanges,
};
</script>
<template>
  <div>
    <div
      class="prometheus-graphs-header d-sm-flex flex-sm-wrap pt-2 pr-1 pb-0 pl-2 border-bottom bg-gray-light"
    >
      <div class="mb-2 pr-2 d-flex d-sm-block">
        <date-time-picker
          ref="dateTimePicker"
          v-model="timeRange"
          class="flex-grow-1"
          :options="$options.timeRanges"
          :utc="false"
        />
      </div>
    </div>
    <dashboard-panel :graph-data="graphData" />
    <gl-form @submit.stop.prevent="onSubmit">
      <gl-form-group
        id="group-id"
        label="Input"
        description="Input a panel yml definition, in the actual implementation `queryRange` would be defined and not `prometheusEndpointPath`"
        label-for=""
      >
        <gl-form-textarea
          v-model="form.ymlInput"
          class="text-monospace"
          style="height: 300px;"
          placeholder="Enter something"
        />
      </gl-form-group>
      <gl-button type="submit" :disabled="form.submitDisabled" variant="success" class=""
        >Submit</gl-button
      >
    </gl-form>
  </div>
</template>
