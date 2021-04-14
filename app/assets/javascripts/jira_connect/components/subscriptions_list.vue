<script>
import { GlButton, GlEmptyState, GlTable } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { removeSubscription } from '~/jira_connect/api';
import { reloadPage } from '~/jira_connect/utils';
import { __, s__ } from '~/locale';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import GroupItemName from './group_item_name.vue';

export default {
  components: {
    GlButton,
    GlEmptyState,
    GlTable,
    GroupItemName,
    TimeagoTooltip,
  },
  inject: {
    subscriptions: {
      default: [],
    },
  },
  data() {
    return {
      loadingItem: null,
    };
  },
  fields: [
    {
      key: 'name',
      label: s__('Integrations|Linked namespaces'),
    },
    {
      key: 'created_at',
      label: __('Added'),
      tdClass: 'gl-vertical-align-middle! gl-w-20p',
    },
    {
      key: 'actions',
      label: '',
      tdClass: 'gl-text-right gl-vertical-align-middle! jira-subscription-actions',
    },
  ],
  i18n: {
    emptyTitle: s__('Integrations|No linked namespaces'),
    emptyDescription: s__(
      'Integrations|Namespaces are the GitLab groups and subgroups you link to this Jira instance.',
    ),
  },
  methods: {
    isEmpty,
    onClick(item) {
      this.loadingItem = item;

      removeSubscription(item.unlink_path)
        .then(() => {
          reloadPage();
        })
        .catch(() => {
          this.loadingItem = null;
        });
    },
  },
};
</script>

<template>
  <div>
    <gl-empty-state
      v-if="isEmpty(subscriptions)"
      :title="$options.i18n.emptyTitle"
      :description="$options.i18n.emptyDescription"
    />
    <gl-table v-else :items="subscriptions" :fields="$options.fields">
      <template #cell(name)="{ item }">
        <group-item-name :group="item.group" />
      </template>
      <template #cell(created_at)="{ item }">
        <timeago-tooltip :time="item.created_at" />
      </template>
      <template #cell(actions)="{ item }">
        <gl-button
          category="secondary"
          :loading="loadingItem === item"
          @click.prevent="onClick(item)"
          >{{ __('Unlink') }}</gl-button
        >
      </template>
    </gl-table>
  </div>
</template>
