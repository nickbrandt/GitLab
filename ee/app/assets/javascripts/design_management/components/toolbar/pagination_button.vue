<script>
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
  props: {
    design: {
      type: Object,
      required: false,
      default: null,
    },
    title: {
      type: String,
      required: true,
    },
    iconName: {
      type: String,
      required: true,
    },
  },
  computed: {
    designLink() {
      if (!this.design) return {};

      return { name: 'design', params: { id: this.design.filename } };
    },
  },
};
</script>

<template>
  <router-link
    :to="designLink"
    :disabled="!design"
    :class="{ disabled: !design }"
    :aria-label="title"
    class="btn btn-default"
  >
    <icon :name="iconName" />
  </router-link>
</template>
