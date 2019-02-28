<script>
import { GlLoadingIcon } from '@gitlab/ui';
import DesignList from '../components/list/index.vue';
import allDesignsQuery from '../queries/allDesigns.graphql';

export default {
  components: {
    GlLoadingIcon,
    DesignList,
  },
  apollo: {
    designs: {
      query: allDesignsQuery,
      error() {
        this.error = true;
      },
    },
  },
  data() {
    return {
      designs: [],
      error: false,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.designs.loading;
    },
  },
};
</script>

<template>
  <div>
    <div class="mt-4">
      <gl-loading-icon v-if="isLoading" :size="2" />
      <div v-else-if="error" class="alert alert-danger">
        {{ __('An error occured while loading designs. Please try again.') }}
      </div>
      <design-list v-else-if="designs.length" :designs="designs" />
      <div v-else>{{ __('No designs found.') }}</div>
    </div>
  </div>
</template>
