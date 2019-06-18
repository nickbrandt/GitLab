<script>
import createFlash from '~/flash';
import { s__ } from '~/locale';
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
      type: String,
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
      result({ data }) {
        if (!data) {
          createFlash(s__('DesignManagement|Could not find design, please try again.'));
          this.$router.push('/designs');
        }
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
      :id="id"
      :is-loading="isLoading"
      :name="design.filename"
      :updated-at="design.updatedAt"
      :updated-by="design.updatedBy"
    />
    <design-image :is-loading="isLoading" :image="design.image" :name="design.filename" />
  </div>
</template>
