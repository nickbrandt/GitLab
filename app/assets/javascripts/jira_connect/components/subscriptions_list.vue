<script>
import { GlButton, GlTable } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import GroupItemName from './group_item_name.vue';

export default {
  components: {
    GlButton,
    GlTable,
    GroupItemName,
    TimeagoTooltip,
  },
  inject: {
    subscriptions: {
      default: [],
    },
  },
  fields: [
    {
      key: 'name',
      label: s__('Integrations|Linked namespaces'),
    },
    {
      key: 'created_at',
      label: __('Added'),
      tdClass: 'gl-vertical-align-middle!',
    },
    {
      key: 'actions',
      label: '',
    },
  ],
  methods: {
    onClick(item) {
      return item;
    },
  },
};
</script>

<template>
  <gl-table :items="subscriptions" :fields="$options.fields">
    <template #cell(name)="{ item }">
      <group-item-name :group="item.group" />
    </template>
    <template #cell(created_at)="{ item }">
      <timeago-tooltip :time="item.created_at" />
    </template>
    <template #cell(actions)="{ item }">
      <gl-button category="secondary" :loading="false" @click.prevent="onClick(item)">{{
        __('Unlink')
      }}</gl-button>
    </template>
  </gl-table>
</template>
