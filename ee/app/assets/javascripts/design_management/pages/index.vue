<script>
import { GlLoadingIcon } from '@gitlab/ui';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import DesignList from '../components/list/index.vue';
import UploadForm from '../components/upload/form.vue';
import allDesignsQuery from '../queries/allDesigns.graphql';
import uploadDesignQuery from '../queries/uploadDesign.graphql';

export default {
  components: {
    GlLoadingIcon,
    DesignList,
    UploadForm,
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
      isSaving: false,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.designs.loading;
    },
  },
  methods: {
    onUploadDesign(files) {
      const file = files[0];

      this.isSaving = true;

      return this.$apollo
        .mutate({
          mutation: uploadDesignQuery,
          variables: {
            name: file.name,
          },
          update: (store, { data: { uploadDesign } }) => {
            const data = store.readQuery({ query: allDesignsQuery });

            data.designs.unshift(uploadDesign);
            store.writeQuery({ query: allDesignsQuery, data });
          },
          optimisticResponse: {
            __typename: 'Mutation',
            uploadDesign: {
              __typename: 'Design',
              id: -1,
              image: '',
              name: file.name,
              commentsCount: 0,
              updatedAt: new Date().toString(),
            },
          },
        })
        .then(() => {
          this.isSaving = false;
        })
        .catch(e => {
          this.isSaving = false;

          createFlash(s__('DesignManagement|Error uploading a new design. Please try again'));

          throw e;
        });
    },
  },
};
</script>

<template>
  <div>
    <upload-form :is-saving="isSaving" @upload="onUploadDesign" />
    <div class="mt-4">
      <gl-loading-icon v-if="isLoading" size="md" />
      <div v-else-if="error" class="alert alert-danger">
        {{ __('An error occurred while loading designs. Please try again.') }}
      </div>
      <design-list v-else-if="designs.length" :designs="designs" />
      <div v-else>{{ __('No designs found.') }}</div>
    </div>
  </div>
</template>
