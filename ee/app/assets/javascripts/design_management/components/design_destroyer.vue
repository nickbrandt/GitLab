<script>
import { __, s__, sprintf } from '~/locale';
import createFlash from '~/flash';
import { ApolloMutation } from 'vue-apollo';
import projectQuery from '../graphql/queries/project.query.graphql';
import destroyDesignMutation from '../graphql/mutations/destroyDesign.mutation.graphql';
import { updateStoreAfterDesignsDelete } from '../utils/design_management_utils';

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
    onError() {
      const design = this.filenames.length > 1 ? __('designs') : __('a design');
      createFlash(
        sprintf(s__('DesignManagement|We could not delete %{design}. Please try again.'), {
          design,
        }),
      );
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
  <apollo-mutation
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
  </apollo-mutation>
</template>
