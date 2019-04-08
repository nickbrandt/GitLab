<script>
import { GlLoadingIcon } from '@gitlab/ui';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import DesignList from '../components/list/index.vue';
import UploadForm from '../components/upload/form.vue';
import EmptyState from '../components/empty_state.vue';
import allDesignsQuery from '../queries/allDesigns.graphql';
import uploadDesignQuery from '../queries/uploadDesign.graphql';
import appDataQuery from '../queries/appData.graphql';
import permissionsQuery from '../queries/permissions.graphql';

export default {
  components: {
    GlLoadingIcon,
    DesignList,
    UploadForm,
    EmptyState,
  },
  apollo: {
    appData: {
      query: appDataQuery,
      manual: true,
      result({ data: { projectPath, issueIid } }) {
        this.projectPath = projectPath;
        this.issueIid = issueIid;
      },
    },
    designs: {
      query: allDesignsQuery,
      error() {
        this.error = true;
      },
    },
    permissions: {
      query: permissionsQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          iid: this.issueIid,
        };
      },
      update: data => data.project.issue.userPermissions,
    },
  },
  data() {
    return {
      designs: [],
      permissions: {
        createDesign: false,
      },
      error: false,
      isSaving: false,
      projectPath: '',
      issueIid: null,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.designs.loading || this.$apollo.queries.permissions.loading;
    },
    canCreateDesign() {
      return this.permissions.createDesign;
    },
    showUploadForm() {
      return this.canCreateDesign && this.hasDesigns;
    },
    hasDesigns() {
      return this.designs.length > 0;
    },
  },
  methods: {
    onUploadDesign(files) {
      if (!this.canCreateDesign) return null;

      const optimisticResponse = Array.from(files).map(file => ({
        __typename: 'Design',
        id: -1,
        image: '',
        name: file.name,
        commentsCount: 0,
        updatedAt: new Date().toString(),
      }));

      this.isSaving = true;

      return this.$apollo
        .mutate({
          mutation: uploadDesignQuery,
          variables: {
            files,
          },
          // update: (store, { data: { uploadDesign } }) => {
          //   const data = store.readQuery({ query: allDesignsQuery });
          //   console.log(data, uploadDesign);

          //   data.designs.unshift(...uploadDesign);
          //   store.writeQuery({ query: allDesignsQuery, data });
          // },
          optimisticResponse: {
            __typename: 'Mutation',
            uploadDesign: optimisticResponse,
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
    <upload-form
      v-if="showUploadForm"
      :can-upload-design="canCreateDesign"
      :is-saving="isSaving"
      @upload="onUploadDesign"
    />
    <div class="mt-4">
      <gl-loading-icon v-if="isLoading" size="md" />
      <div v-else-if="error" class="alert alert-danger">
        {{ __('An error occurred while loading designs. Please try again.') }}
      </div>
      <design-list v-else-if="hasDesigns" :designs="designs" />
      <empty-state
        v-else
        :can-upload-design="canCreateDesign"
        :is-saving="isSaving"
        @upload="onUploadDesign"
      />
    </div>
    <router-view />
  </div>
</template>
