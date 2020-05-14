<script>
import MetricCard from '../../shared/components/metric_card.vue';
import { timeMetricsData as mockTimeMetricsData } from '../../../../../../spec/frontend/analytics/cycle_analytics/mock_data';

export default {
  name: 'TimeMetricsCard',
  components: {
    MetricCard,
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
    additionalParams: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      data: [],
      loading: false,
    };
  },
  watch: {
    additionalParams() {
      this.fetchData();
    },
  },
  mounted() {
    this.fetchData();
  },
  methods: {
    fetchData() {
      this.data = mockTimeMetricsData;
    },
  },
  render() {
    return this.$scopedSlots.default({
      metrics: this.data,
      loading: this.loading,
    });
  },
};
</script>
