<script>
import { GlSkeletonLoading } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import Poll from '~/lib/utils/poll';
import TerraformPlan from './terraform_plan.vue';

export default {
  name: 'MRWidgetTerraformContainer',
  components: {
    GlSkeletonLoading,
    TerraformPlan,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      loading: true,
      plans: {},
    };
  },
  created() {
    this.fetchPlans();
  },
  methods: {
    fetchPlans() {
      this.loading = true;

      const poll = new Poll({
        resource: {
          fetchPlans: () => axios.get(this.endpoint),
        },
        data: this.endpoint,
        method: 'fetchPlans',
        successCallback: ({ data }) => {
          this.plans = data;

          if (Object.keys(this.plans).length) {
            this.loading = false;
            poll.stop();
          }
        },
        errorCallback: () => {
          this.plans = { bad_plan: {} };
          this.loading = false;
          poll.stop();
        },
      });

      poll.makeRequest();
    },
  },
};
</script>

<template>
  <section class="mr-widget-section">
    <div v-if="loading" class="mr-widget-body media">
      <gl-skeleton-loading />
    </div>

    <terraform-plan
      v-for="(plan, key) in plans"
      v-else
      :key="key"
      :plan="plan"
      class="mr-widget-body media"
    />
  </section>
</template>
