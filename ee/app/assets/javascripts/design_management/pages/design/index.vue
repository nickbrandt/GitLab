<script>
import Toolbar from '../../components/toolbar/index.vue';
import DesignImage from '../../components/image.vue';
import getDesignQuery from '../../queries/getDesign.graphql';

export default {
  components: {
    DesignImage,
    Toolbar,
  },
  props: {
    id: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      design: {},
    };
  },
  apollo: {
    design: {
      query: getDesignQuery,
      variables() {
        return {
          id: this.id,
        };
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.design.loading;
    },
  },
};
</script>

<template>
  <div class="design-detail fixed-top w-100 position-bottom-0 d-flex flex-column">
    <toolbar
      :is-loading="isLoading"
      :name="design.name"
      :updated-at="design.updatedAt"
      :updated-by="design.updatedBy"
    />
    <design-image :is-loading="isLoading" :image="design.image" :name="design.name" />
  </div>
</template>
