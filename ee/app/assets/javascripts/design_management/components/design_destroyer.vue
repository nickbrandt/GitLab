<script>
import { ApolloMutation } from 'vue-apollo';
import projectQuery from '../graphql/queries/project.query.graphql';
import destroyDesignMutation from '../graphql/mutations/destroyDesign.mutation.graphql';
import {
  updateStoreAfterDesignsDelete,
  onDesignDeletionError,
} from '../utils/design_management_utils';

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
    onError(...args) {
      onDesignDeletionError(...args);
    },
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
  <ApolloMutation
    v-slot="{ mutate, loading, error }"
    :mutation="$options.destroyDesignMutation"
    :variables="{
      filenames,
      projectPath,
      iid,
    }"
    :update="updateStoreAfterDelete"
    @error="onError"
    v-on="$listeners"
  >
    <slot v-bind="{ mutate, loading, error }"></slot>
  </ApolloMutation>
</template>
