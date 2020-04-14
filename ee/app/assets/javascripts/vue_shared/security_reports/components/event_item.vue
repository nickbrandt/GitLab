<script>
import { GlTooltipDirective, GlDeprecatedButton } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  name: 'EventItem',
  components: {
    Icon,
    TimeAgoTooltip,
    GlDeprecatedButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    author: {
      type: Object,
      required: true,
    },
    createdAt: {
      type: String,
      required: false,
      default: '',
    },
    iconName: {
      type: String,
      required: false,
      default: 'plus',
    },
    iconClass: {
      type: String,
      required: false,
      default: 'ci-status-icon-success',
    },
    actionButtons: {
      type: Array,
      required: false,
      default: () => [],
    },
    showRightSlot: {
      type: Boolean,
      required: false,
      default: false,
    },
    showActionButtons: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
};
</script>

<template>
  <div class="d-flex align-items-center">
    <div class="circle-icon-container" :class="iconClass">
      <icon :size="16" :name="iconName" />
    </div>
    <div class="ml-3 flex-grow-1" data-qa-selector="event_item_content">
      <div class="note-header-info pb-0">
        <a
          :href="author.path"
          :data-user-id="author.id"
          :data-username="author.username"
          class="js-author js-user-link"
        >
          <strong class="note-header-author-name">{{ author.name }}</strong>
          <span v-if="author.status_tooltip_html" v-html="author.status_tooltip_html"></span>
          <span class="note-headline-light">@{{ author.username }}</span>
        </a>
        <span class="note-headline-light note-headline-meta">
          <template v-if="createdAt">
            <span class="system-note-separator">·</span>
            <time-ago-tooltip :time="createdAt" tooltip-placement="bottom" />
          </template>
        </span>
      </div>
      <slot></slot>
    </div>

    <slot v-if="showRightSlot" name="right-content"></slot>

    <div v-else-if="showActionButtons" class="align-self-start">
      <gl-deprecated-button
        v-for="button in actionButtons"
        :key="button.title"
        v-gl-tooltip
        class="px-1"
        variant="transparent"
        :title="button.title"
        @click="button.onClick"
      >
        <icon :name="button.iconName" class="link-highlight" />
      </gl-deprecated-button>
    </div>
  </div>
</template>
