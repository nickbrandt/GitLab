<script>
import { GlIcon, GlLink, GlTable, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    GlIcon,
    GlLink,
    GlTable,
    TimeAgoTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    integrations: {
      type: Array,
      required: true,
    },
    showUpdatedAt: {
      type: Boolean,
      required: false,
      default: false,
    },
    emptyText: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  computed: {
    fields() {
      return [
        {
          key: 'active',
          label: '',
          thClass: 'gl-w-10',
        },
        {
          key: 'name',
          label: __('Integration'),
          thClass: 'gl-w-quarter',
        },
        {
          key: 'description',
          label: __('Description'),
          thClass: 'gl-display-none d-sm-table-cell',
          tdClass: 'gl-display-none d-sm-table-cell',
        },
        {
          key: 'updated_at',
          label: this.showUpdatedAt ? __('Last updated') : '',
          thClass: 'gl-w-20p',
        },
      ];
    },
  },
};
</script>

<template>
  <gl-table :items="integrations" :fields="fields" :empty-text="emptyText" show-empty fixed>
    <template #cell(active)="{ item }">
      <gl-icon
        v-if="item.active"
        v-gl-tooltip
        name="check"
        class="gl-text-green-500"
        :title="
          sprintf(s__('Integrations|%{integrationName}: active'), {
            integrationName: item.name,
          })
        "
      />
    </template>

    <template #cell(name)="{ item }">
      <gl-link
        :href="item.edit_path"
        class="gl-font-weight-bold"
        :data-qa-selector="`${item.type}_link`"
      >
        {{ item.name }}
      </gl-link>
    </template>

    <template #cell(updated_at)="{ item }">
      <time-ago-tooltip v-if="showUpdatedAt && item.updated_at" :time="item.updated_at" />
    </template>
  </gl-table>
</template>
