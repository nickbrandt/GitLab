<script>
import { s__, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import PaginationButton from './pagination_button.vue';
import allDesignsQuery from '../../queries/allDesigns.graphql';

export default {
  apollo: {
    designs: {
      query: allDesignsQuery,
    },
  },
  components: {
    Icon,
    PaginationButton,
  },
  props: {
    id: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      designs: [],
    };
  },
  computed: {
    designsCount() {
      return this.designs.length;
    },
    currentIndex() {
      return this.designs.findIndex(design => design.id === this.id);
    },
    paginationText() {
      return sprintf(s__('DesignManagement|%{current_design} of %{designs_count}'), {
        current_design: this.currentIndex + 1,
        designs_count: this.designsCount,
      });
    },
    previousDesign() {
      if (!this.designsCount) return null;

      return this.designs[this.currentIndex - 1];
    },
    nextDesign() {
      if (!this.designsCount) return null;

      return this.designs[this.currentIndex + 1];
    },
  },
};
</script>

<template>
  <div v-if="designsCount" class="d-flex align-items-center">
    {{ paginationText }}
    <div class="btn-group ml-3">
      <pagination-button
        :design="previousDesign"
        :title="s__('DesignManagement|Go to previous design')"
        icon-name="angle-left"
        class="js-previous-design"
      />
      <pagination-button
        :design="nextDesign"
        :title="s__('DesignManagement|Go to next design')"
        icon-name="angle-right"
        class="js-next-design"
      />
    </div>
  </div>
</template>
