<script>
import _ from 'underscore';
import { mapActions, mapState, mapGetters } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import SubscriptionTableRow from './subscription_table_row.vue';
import {
  CUSTOMER_PORTAL_URL,
  TABLE_TYPE_DEFAULT,
  TABLE_TYPE_FREE,
  TABLE_TYPE_TRIAL,
} from '../constants';
import { s__, sprintf } from '~/locale';

export default {
  name: 'SubscriptionTable',
  components: {
    SubscriptionTableRow,
    GlLoadingIcon,
  },
  computed: {
    ...mapState('subscription', ['isLoading', 'hasError', 'plan', 'tables', 'endpoint']),
    ...mapGetters('subscription', ['isFreePlan']),
    subscriptionHeader() {
      let suffix = '';
      if (!this.isFreePlan && this.plan.trial) {
        suffix = `${s__('SubscriptionTable|Trial')}`;
      }
      return sprintf(s__('SubscriptionTable|GitLab.com %{planName} %{suffix}'), {
        planName: this.isFreePlan ? s__('SubscriptionTable|Free') : _.escape(this.plan.name),
        suffix,
      });
    },
    actionButtonText() {
      return this.isFreePlan ? s__('SubscriptionTable|Upgrade') : s__('SubscriptionTable|Manage');
    },
    visibleRows() {
      let tableKey = TABLE_TYPE_DEFAULT;

      if (this.plan.code === null) {
        tableKey = TABLE_TYPE_FREE;
      } else if (this.plan.trial) {
        tableKey = TABLE_TYPE_TRIAL;
      }

      return this.tables[tableKey].rows;
    },
  },
  mounted() {
    this.fetchSubscription();
  },
  methods: {
    ...mapActions('subscription', ['fetchSubscription']),
  },
  customerPortalUrl: CUSTOMER_PORTAL_URL,
};
</script>

<template>
  <div>
    <div
      v-if="!isLoading && !hasError"
      class="card prepend-top-default subscription-table js-subscription-table"
    >
      <div class="js-subscription-header card-header">
        <strong> {{ subscriptionHeader }} </strong>
        <div class="controls">
          <a
            :href="$options.customerPortalUrl"
            target="_blank"
            rel="noopener noreferrer"
            class="btn btn-inverted-secondary"
          >
            {{ actionButtonText }}
          </a>
        </div>
      </div>
      <div class="card-body flex-grid d-flex flex-column flex-sm-row flex-md-row flex-lg-column">
        <subscription-table-row
          v-for="(row, i) in visibleRows"
          :key="`subscription-rows-${i}`"
          :header="row.header"
          :columns="row.columns"
          :is-free-plan="isFreePlan"
        />
      </div>
    </div>

    <gl-loading-icon
      v-else-if="isLoading && !hasError"
      :label="s__('SubscriptionTable|Loading subscriptions')"
      :size="3"
      class="prepend-top-10 append-bottom-10"
    />
  </div>
</template>
