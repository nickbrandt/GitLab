<script>
import { GlAlert } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';

export default {
  name: 'Dag',
  components: {
    GlAlert,
  },
  props: {
    graphUrl: {
      type: String,
      required: false,
      default: ''
    }
  },
  data() {
    return {
      showFailureAlert: false,
    }
  },
  mounted() {
    const drawGraph = this.drawGraph;
    const reportFailure = this.reportFailure;

    if (!this.graphUrl) {
      reportFailure();
      return;
    }

    axios.get(this.graphUrl)
      .then((response) => {
        drawGraph(response.data);
      })
      .catch(reportFailure);
  },
  computed: {
    shouldDisplayGraph() {
      return !this.showFailureAlert;
    },
  },
  methods: {
    drawGraph (data) {
      return data;
    },
    hideAlert() {
      this.showFailureAlert = false;
    },
    reportFailure() {
      this.showFailureAlert = true;
    }
  },
};

</script>
<template>
  <div>
    <gl-alert v-if="showFailureAlert" variant="danger" @dismiss="hideAlert">
      {{__('We are currently unable to fetch data for this graph.')}}
    </gl-alert>
    <div v-if="shouldDisplayGraph" data-testid="dag-graph-container">
      <!-- graph goes here -->
    </div>
  </div>
</template>
