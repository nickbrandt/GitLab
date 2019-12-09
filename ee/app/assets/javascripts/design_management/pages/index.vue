<script>
import { GlLoadingIcon, GlEmptyState, GlButton } from '@gitlab/ui';
import _ from 'underscore';
import createFlash from '~/flash';
import { s__, sprintf } from '~/locale';
import UploadButton from '../components/upload/button.vue';
import DeleteButton from '../components/delete_button.vue';
import Design from '../components/list/item.vue';
import DesignDestroyer from '../components/design_destroyer.vue';
import DesignVersionDropdown from '../components/upload/design_version_dropdown.vue';
import uploadDesignMutation from '../graphql/mutations/uploadDesign.mutation.graphql';
import permissionsQuery from '../graphql/queries/permissions.query.graphql';
import projectQuery from '../graphql/queries/project.query.graphql';
import allDesignsMixin from '../mixins/all_designs';
import { UPLOAD_DESIGN_ERROR } from '../utils/error_messages';
import { updateStoreAfterUploadDesign } from '../utils/cache_update';

const MAXIMUM_FILE_UPLOAD_LIMIT = 10;

export default {
  components: {
    GlLoadingIcon,
    UploadButton,
    GlEmptyState,
    GlButton,
    Design,
    DesignDestroyer,
    DesignVersionDropdown,
    DeleteButton,
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
      filesToBeSaved: [],
      selectedDesigns: [],
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.designs.loading || this.$apollo.queries.permissions.loading;
    },
    isSaving() {
      return this.filesToBeSaved.length > 0;
    },
    canCreateDesign() {
      return this.permissions.createDesign;
    },
    showToolbar() {
      return this.canCreateDesign && this.allVersions.length > 0;
    },
    hasDesigns() {
      return this.designs.length > 0;
    },
    hasSelectedDesigns() {
      return this.selectedDesigns.length > 0;
    },
    canDeleteDesigns() {
      return this.isLatestVersion && this.hasSelectedDesigns;
    },
    projectQueryBody() {
      return {
        query: projectQuery,
        variables: { fullPath: this.projectPath, iid: this.issueIid, atVersion: null },
      };
    },
    selectAllButtonText() {
      return this.hasSelectedDesigns
        ? s__('DesignManagement|Deselect all')
        : s__('DesignManagement|Select all');
    },
  },
  methods: {
    onUploadDesign(files) {
      if (!this.canCreateDesign) return null;

      if (files.length > MAXIMUM_FILE_UPLOAD_LIMIT) {
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

      this.filesToBeSaved = Array.from(files);
      const optimisticResponse = this.filesToBeSaved.map(file => ({
        // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
        // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
        __typename: 'Design',
        id: -_.uniqueId(),
        image: '',
        filename: file.name,
        fullPath: '',
        notesCount: 0,
        event: 'NONE',
        diffRefs: {
          __typename: 'DiffRefs',
          baseSha: '',
          startSha: '',
          headSha: '',
        },
        discussions: {
          __typename: 'DesignDiscussion',
          edges: [],
        },
        versions: {
          __typename: 'DesignVersionConnection',
          edges: {
            __typename: 'DesignVersionEdge',
            node: {
              __typename: 'DesignVersion',
              id: -_.uniqueId(),
              sha: -_.uniqueId(),
            },
          },
        },
      }));

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
            updateStoreAfterUploadDesign(store, designManagementUpload, this.projectQueryBody);
          },
          optimisticResponse: {
            // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
            // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
            __typename: 'Mutation',
            designManagementUpload: {
              __typename: 'DesignManagementUploadPayload',
              designs: optimisticResponse,
            },
          },
        })
        .then(() => {
          this.$router.push({ name: 'designs' });
        })
        .catch(e => {
          createFlash(UPLOAD_DESIGN_ERROR);
          throw e;
        })
        .finally(() => {
          this.filesToBeSaved = [];
        });
    },
    changeSelectedDesigns(filename) {
      if (this.isDesignSelected(filename)) {
        this.selectedDesigns = this.selectedDesigns.filter(design => design !== filename);
      } else {
        this.selectedDesigns.push(filename);
      }
    },
    toggleDesignsSelection() {
      if (this.hasSelectedDesigns) {
        this.selectedDesigns = [];
      } else {
        this.selectedDesigns = this.designs.map(design => design.filename);
      }
    },
    isDesignSelected(filename) {
      return this.selectedDesigns.includes(filename);
    },
    isDesignToBeSaved(filename) {
      return this.filesToBeSaved.some(file => file.name === filename);
    },
    canSelectDesign(filename) {
      return this.isLatestVersion && this.canCreateDesign && !this.isDesignToBeSaved(filename);
    },
    onDesignDelete() {
      this.selectedDesigns = [];
      if (this.$route.query.version) this.$router.push({ name: 'designs' });
    },
  },
  beforeRouteUpdate(to, from, next) {
    this.selectedDesigns = [];
    next();
  },
};
</script>

<template>
  <div>
    <header v-if="showToolbar" class="row-content-block border-top-0 p-2 d-flex">
      <div class="d-flex justify-content-between align-items-center w-100">
        <design-version-dropdown />
        <div v-if="hasDesigns" class="d-flex qa-selector-toolbar">
          <gl-button
            v-if="isLatestVersion"
            variant="link"
            class="mr-2 js-select-all"
            @click="toggleDesignsSelection"
            >{{ selectAllButtonText }}</gl-button
          >
          <design-destroyer
            v-slot="{ mutate, loading, error }"
            :filenames="selectedDesigns"
            :project-path="projectPath"
            :iid="issueIid"
            @done="onDesignDelete"
          >
            <delete-button
              v-if="isLatestVersion"
              :is-deleting="loading"
              button-class="btn-danger btn-inverted mr-2"
              :has-selected-designs="hasSelectedDesigns"
              @deleteSelectedDesigns="mutate()"
            >
              {{ s__('DesignManagement|Delete selected') }}
              <gl-loading-icon v-if="loading" inline class="ml-1" />
            </delete-button>
          </design-destroyer>
          <upload-button v-if="canCreateDesign" :is-saving="isSaving" @upload="onUploadDesign" />
        </div>
      </div>
    </header>
    <div class="mt-4">
      <gl-loading-icon v-if="isLoading" size="md" />
      <div v-else-if="error" class="alert alert-danger">
        {{ __('An error occurred while loading designs. Please try again.') }}
      </div>
      <ol v-else-if="hasDesigns" class="list-unstyled row">
        <li v-for="design in designs" :key="design.id" class="col-md-6 col-lg-4 mb-3">
          <design v-bind="design" :is-loading="isDesignToBeSaved(design.filename)" />
          <input
            v-if="canSelectDesign(design.filename)"
            :checked="isDesignSelected(design.filename)"
            type="checkbox"
            class="design-checkbox"
            @change="changeSelectedDesigns(design.filename)"
          />
        </li>
      </ol>
      <gl-empty-state
        v-else
        :title="s__('DesignManagement|The one place for your designs')"
        :description="
          s__(`DesignManagement|Upload and view the latest designs for this issue.
            Consistent and easy to find, so everyone is up to date.`)
        "
      >
        <template #actions>
          <div v-if="canCreateDesign" class="center">
            <upload-button :is-saving="isSaving" @upload="onUploadDesign" />
          </div>
        </template>
      </gl-empty-state>
    </div>
    <router-view />
  </div>
</template>
