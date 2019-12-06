<script>
import { ApolloMutation } from 'vue-apollo';
import createFlash from '~/flash';
import projectQuery from '../graphql/queries/project.query.graphql';
import destroyDesignMutation from '../graphql/mutations/destroyDesign.mutation.graphql';
import { updateStoreAfterDesignsDelete } from '../utils/cache_update';

export default {
  components: {
    ApolloMutation,
  },
  props: {
    filenames: {
      type: Array,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    iid: {
      type: String,
      required: true,
    },
  },
  computed: {
    projectQueryBody() {
      return {
        query: projectQuery,
        variables: { fullPath: this.projectPath, iid: this.iid, atVersion: null },
      };
    },
  },
  methods: {
    updateStoreAfterDelete(
      store,
      {
        data: { designManagementDelete },
      },
    ) {
      updateStoreAfterDesignsDelete(
        store,
        designManagementDelete,
        this.projectQueryBody,
        this.filenames,
      );
    },
  },
  destroyDesignMutation,
};
</script>

<template>
  <apollo-mutation
    v-slot="{ mutate, loading, error }"
    :mutation="$options.destroyDesignMutation"
    :variables="{
      filenames,
      projectPath,
      iid,
    }"
    :update="updateStoreAfterDelete"
    v-on="$listeners"
  >
    <slot v-bind="{ mutate, loading, error }"></slot>
  </apollo-mutation>
</template>
