<script>
import Api from 'ee/api';
import { __ } from '~/locale';
import createFlash from '~/flash';
import { slugify } from '~/lib/utils/text_utility';
import MetricCard from '../../shared/components/metric_card.vue';
import { removeFlash } from '../utils';

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
      default: () => ({}),
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
      removeFlash();
      this.loading = true;
      return Api.cycleAnalyticsTimeSummaryData(this.groupPath, this.additionalParams)
        .then(({ data }) => {
          this.data = data.map(({ title: label, ...rest }) => ({
            ...rest,
            label,
            key: slugify(label),
          }));
        })
        .catch(() => {
          createFlash(
            __('There was an error while fetching value stream analytics time summary data.'),
          );
        })
        .finally(() => {
          this.loading = false;
        });
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
