<script>
import { s__, sprintf } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { GlTooltipDirective } from '@gitlab/ui';

export default {
  directives: { GlTooltip: GlTooltipDirective },
  mixins: [timeagoMixin],
  props: {
    userLists: {
      type: Array,
      required: true,
    },
  },
  translations: {
    createdTimeagoLabel: s__('created %{timeago}'),
  },
  methods: {
    createdTimeago(list) {
      return sprintf(this.$options.translations.createdTimeagoLabel, {
        timeago: this.timeFormatted(list.created_at),
      });
    },
    displayList(list) {
      return list.user_xids.replace(/,/g, ', ');
    },
  },
};
</script>
<template>
  <div>
    <div
      v-for="list in userLists"
      :key="list.id"
      data-testid="ffUserList"
      class="gl-border-b-solid gl-border-gray-100 gl-border-b-1 gl-w-full gl-py-4 gl-display-flex gl-justify-content-space-between"
    >
      <div class="gl-display-flex gl-flex-direction-column gl-overflow-hidden gl-flex-grow-1">
        <span data-testid="ffUserListName" class="gl-font-weight-bold gl-mb-2">{{
          list.name
        }}</span>
        <span
          v-gl-tooltip
          :title="tooltipTitle(list.created_at)"
          data-testid="ffUserListTimestamp"
          class="gl-text-gray-500 gl-mb-2"
        >
          {{ createdTimeago(list) }}
        </span>
        <span data-testid="ffUserListIds" class="gl-str-truncated">{{ displayList(list) }}</span>
      </div>
    </div>
  </div>
</template>
