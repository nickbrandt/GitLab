<script>
import { __ } from '~/locale';
import tooltip from '~/vue_shared/directives/tooltip';
import { spriteIcon } from '~/lib/utils/common_utils';
import Store from '../stores/sidebar_store';
import { GlLoadingIcon } from '@gitlab/ui';

export default {
  name: 'SidebarItemEpic',
  directives: {
    tooltip,
  },
  components: {
    GlLoadingIcon,
  },
  props: {
    blockTitle: {
      type: String,
      required: false,
      default: __('Epic'),
    },
    initialEpic: {
      type: Object,
      required: false,
      default: () => null,
    },
  },
  data() {
    return {
      store: !this.initialEpic ? new Store() : {},
    };
  },
  computed: {
    isLoading() {
      return this.initialEpic ? false : this.store.isFetching.epic;
    },
    epic() {
      return this.initialEpic || this.store.epic;
    },
    epicIcon() {
      return spriteIcon('epic');
    },
    epicUrl() {
      return this.epic.url;
    },
    epicTitle() {
      return this.epic.title;
    },
    hasEpic() {
      return this.epicUrl && this.epicTitle;
    },
    collapsedTitle() {
      return this.hasEpic ? this.epicTitle : __('None');
    },
    tooltipTitle() {
      if (!this.hasEpic) {
        return __('Epic');
      }
      let tooltipTitle = this.epicTitle;

      if (this.epic.human_readable_end_date || this.epic.human_readable_timestamp) {
        tooltipTitle += '<br />';
        tooltipTitle += this.epic.human_readable_end_date
          ? `${this.epic.human_readable_end_date} `
          : '';
        tooltipTitle += this.epic.human_readable_timestamp
          ? `(${this.epic.human_readable_timestamp})`
          : '';
      }

      return tooltipTitle;
    },
  },
};
</script>

<template>
  <div>
    <div
      v-tooltip
      :title="tooltipTitle"
      class="sidebar-collapsed-icon"
      data-container="body"
      data-placement="left"
      data-html="true"
      data-boundary="viewport"
    >
      <div v-html="epicIcon"></div>
      <span v-if="!isLoading" class="collapse-truncated-title">{{ collapsedTitle }}</span>
    </div>
    <div class="title hide-collapsed">
      {{ blockTitle }}
      <gl-loading-icon v-if="isLoading" :inline="true" />
    </div>
    <div v-if="!isLoading" class="value hide-collapsed">
      <a v-if="hasEpic" :href="epicUrl" class="bold">{{ epicTitle }}</a>
      <span v-else class="no-value">{{ __('None') }}</span>
    </div>
  </div>
</template>
