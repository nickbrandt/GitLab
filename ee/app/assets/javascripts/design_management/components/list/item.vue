<script>
import Icon from '~/vue_shared/components/icon.vue';
import Timeago from '~/vue_shared/components/time_ago_tooltip.vue';
import { n__ } from '~/locale';

export default {
  components: {
    Icon,
    Timeago,
  },
  props: {
    commentsCount: {
      type: Number,
      required: true,
    },
    image: {
      type: String,
      required: true,
    },
    name: {
      type: String,
      required: true,
    },
    updatedAt: {
      type: String,
      required: true,
    },
  },
  computed: {
    commentsLabel() {
      return n__('%d comment', '%d comments', this.commentsCount);
    },
  },
};
</script>

<template>
  <div class="card js-design-list-item">
    <div class="card-body p-0">
      <img :src="image" :alt="name" class="block ml-auto mr-auto design-img" height="230" />
    </div>
    <div class="card-footer d-flex">
      <div class="d-flex flex-column">
        <span class="bold">{{ name }}</span>
        <span>{{ __('Updated') }} <timeago :time="updatedAt" tooltip-placement="bottom"/></span>
      </div>
      <div class="ml-auto d-flex align-items-center text-secondary">
        <icon name="comments" />
        <span :aria-label="commentsLabel" class="ml-1">
          {{ commentsCount }}
        </span>
      </div>
    </div>
  </div>
</template>
