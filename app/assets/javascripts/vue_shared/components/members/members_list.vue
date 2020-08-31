<script>
import { GlTable, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import initUserPopovers from '~/user_popovers';
import MemberInfo from './member_info.vue';

const FIELDS = [
  {
    key: 'account',
    label: __('Account'),
  },
  {
    key: 'source',
    label: __('Source'),
    optional: true,
    thClass: 'col-meta',
  },
  {
    key: 'granted',
    label: __('Access Granted'),
    optional: true,
    thClass: 'col-meta',
  },
  {
    key: 'invited',
    label: __('Invited'),
    optional: true,
    thClass: 'col-meta',
  },
  {
    key: 'requested',
    label: __('Requested'),
    optional: true,
    thClass: 'col-meta',
  },
  {
    key: 'expires',
    label: __('Access Expires'),
    thClass: 'col-meta',
  },
  {
    key: 'maxRole',
    label: __('Max Role'),
    thClass: 'col-role',
  },
  {
    key: 'expiration',
    label: __('Expiration'),
    thClass: 'col-expiration',
  },
  {
    key: 'actions',
    thClass: 'col-actions',
  },
];

export default {
  name: 'MembersList',
  components: {
    GlTable,
    MemberInfo,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    sourceId: {
      type: Number,
      required: false,
      default: null,
    },
    currentUserId: {
      type: Number,
      required: false,
      default: null,
    },
    members: {
      type: Array,
      required: false,
      default: () => [],
    },
    optionalFields: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    fields() {
      return FIELDS.filter(field => !field.optional || this.showOptionalField(field.key));
    },
  },
  mounted() {
    initUserPopovers(this.$el.querySelectorAll('.js-user-link'));
  },
  methods: {
    showOptionalField(key) {
      return this.optionalFields.includes(key);
    },
    sourceGroup(source) {
      if (!source || source.id === this.sourceId) {
        return null;
      }

      return source;
    },
  },
};
</script>

<template>
  <gl-table
    class="members-table"
    head-variant="white"
    stacked="lg"
    :fields="fields"
    :items="members"
    thead-class="border-bottom"
    :empty-text="__('No members found')"
    show-empty
  >
    <template #cell(account)="{ item }">
      <member-info :current-user-id="currentUserId" :member="item" />
    </template>

    <template #cell(source)="{ item: { source } }">
      <span v-if="!sourceGroup(source)">{{ __('Direct member') }}</span>
      <a v-else v-gl-tooltip.hover :title="__('Inherited')" :href="source.webUrl">{{
        source.name
      }}</a>
    </template>

    <template #head(actions)="{ label }">
      <span data-testid="col-actions" class="gl-sr-only">{{ label }}</span>
    </template>
  </gl-table>
</template>
