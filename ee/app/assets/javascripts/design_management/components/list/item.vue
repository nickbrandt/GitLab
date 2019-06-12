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
    id: {
      type: [Number, String],
      required: true,
    },
    commentsCount: {
      type: Number,
      required: false,
      default: 0,
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
      required: false,
      default: null,
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
  <router-link
    :to="{ name: 'design', params: { id: name } }"
    class="card cursor-pointer text-plain js-design-list-item"
  >
    <div class="card-body p-0">
      <img :src="image" :alt="name" class="block ml-auto mr-auto mw-100 design-img" height="230" />
    </div>
    <div class="card-footer d-flex w-100">
      <div class="d-flex flex-column str-truncated-100">
        <span class="bold str-truncated-100">{{ name }}</span>
        <span v-if="updatedAt" class="str-truncated-100">
          {{ __('Updated') }} <timeago :time="updatedAt" tooltip-placement="bottom" />
        </span>
      </div>
      <div v-if="commentsCount" class="ml-auto d-flex align-items-center text-secondary">
        <icon name="comments" class="ml-1" />
        <span :aria-label="commentsLabel" class="ml-1">
          {{ commentsCount }}
        </span>
      </div>
    </div>
  </router-link>
</template>

<style scoped>
.card:hover {
  text-decoration: none;
}
</style>
