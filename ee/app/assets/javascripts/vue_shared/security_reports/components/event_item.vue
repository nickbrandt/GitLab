<script>
import Icon from '~/vue_shared/components/icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  name: 'EventItem',
  components: {
    Icon,
    TimeAgoTooltip,
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
    iconStyle: {
      type: String,
      required: false,
      default: 'ci-status-icon-success',
    },
  },
};
</script>

<template>
  <div class="d-flex align-items-center">
    <div class="circle-icon-container" :class="iconStyle">
      <icon :size="16" :name="iconName" />
    </div>
    <div class="ml-3">
      <div class="note-header-info pb-0">
        <a
          :href="author.path"
          :data-user-id="author.id"
          :data-username="author.username"
          class="js-author"
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
  </div>
</template>
