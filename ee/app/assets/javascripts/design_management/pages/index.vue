<script>
import { GlLoadingIcon } from '@gitlab/ui';
import _ from 'underscore';
import createFlash from '~/flash';
import { s__, sprintf } from '~/locale';
import DesignList from '../components/list/index.vue';
import UploadForm from '../components/upload/form.vue';
import EmptyState from '../components/empty_state.vue';
import allDesignsQuery from '../queries/allDesigns.graphql';
import uploadDesignMutation from '../queries/uploadDesign.graphql';
import permissionsQuery from '../queries/permissions.graphql';
import allDesignsMixin from '../mixins/all_designs';

const MAXIMUM_FILE_UPLOAD_LIMIT = 10;

export default {
  components: {
    GlLoadingIcon,
    DesignList,
    UploadForm,
    EmptyState,
  },
  mixins: [allDesignsMixin],
  apollo: {
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
      permissions: {
        createDesign: false,
      },
      isSaving: false,
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

      if (files.length >= MAXIMUM_FILE_UPLOAD_LIMIT) {
        createFlash(
          sprintf(
            s__(
              'DesignManagement|The maximum number of designs allowed to be uploaded is %{upload_limit}. Please try again.',
            ),
            {
              upload_limit: MAXIMUM_FILE_UPLOAD_LIMIT,
            },
          ),
        );

        return null;
      }

      const optimisticResponse = Array.from(files).map(file => ({
        __typename: 'Design',
        id: -_.uniqueId(),
        image: '',
        filename: file.name,
      }));

      this.isSaving = true;

      return this.$apollo
        .mutate({
          mutation: uploadDesignMutation,
          variables: {
            files,
            projectPath: this.projectPath,
            iid: this.issueIid,
          },
          context: {
            hasUpload: true,
          },
          update: (store, { data: { designManagementUpload } }) => {
            const data = store.readQuery({
              query: allDesignsQuery,
              variables: { fullPath: this.projectPath, iid: this.issueIid },
            });
            const newDesigns = data.project.issue.designs.designs.edges.reduce((acc, design) => {
              if (!acc.find(d => d.filename === design.node.filename)) {
                acc.push(design.node);
              }

              return acc;
            }, designManagementUpload.designs);
            const newQueryData = {
              project: {
                __typename: 'Project',
                issue: {
                  __typename: 'Issue',
                  designs: {
                    __typename: 'DesignCollection',
                    designs: {
                      __typename: 'DesignConnection',
                      edges: newDesigns.map(design => ({
                        __typename: 'DesignEdge',
                        node: design,
                      })),
                    },
                  },
                },
              },
            };

            store.writeQuery({
              query: allDesignsQuery,
              variables: { fullPath: this.projectPath, iid: this.issueIid },
              data: newQueryData,
            });
          },
          optimisticResponse: {
            __typename: 'Mutation',
            designManagementUpload: {
              __typename: 'DesignManagementUploadPayload',
              designs: optimisticResponse,
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
