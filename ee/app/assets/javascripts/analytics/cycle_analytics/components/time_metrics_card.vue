<script>
import Api from 'ee/api';
import { __, s__ } from '~/locale';
import createFlash from '~/flash';
import { slugify } from '~/lib/utils/text_utility';
import MetricCard from '../../shared/components/metric_card.vue';
import { removeFlash } from '../utils';

const I18N_TEXT = {
  'lead-time': s__('ValueStreamAnalytics|Median time from issue created to issue closed.'),
  'cycle-time': s__('ValueStreamAnalytics|Median time from first commit to issue closed.'),
};

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
          this.data = data.map(({ title: label, ...rest }) => {
            const key = slugify(label);
            return {
              ...rest,
              label,
              key,
              tooltipText: I18N_TEXT[key] || '',
            };
          });
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
