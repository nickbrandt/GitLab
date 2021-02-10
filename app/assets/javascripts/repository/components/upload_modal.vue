<script>
import { GlModal, GlSprintf } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { ContentTypeMultipartFormData } from '~/lib/utils/headers';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import eventHub from '../event_hub';
import { I18N_UPLOAD_MODAL } from '../constants';

export default {
  components: { GlModal, GlSprintf, UploadDropzone },
  props: {
    openModal: {
      type: String,
      required: true,
    },
    modalId: {
      type: String,
      required: true,
    },
    refBranch: {
      type: String,
      required: true,
    },
    userPermissions: {
      type: Object,
      required: true,
    },
    createBlobPath: {
      type: String,
      required: true,
    },
    patchBranchName: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      actionPrimary: {
        text: I18N_UPLOAD_MODAL.actionPrimaryText,
        attributes: [
          { variant: 'success' },
          { category: 'primary' },
          { 'data-testid': 'submit-commit' },
        ],
      },
      actionCancel: {
        text: I18N_UPLOAD_MODAL.actionCancelText,
        attributes: [{ 'data-testid': 'cancel-commit' }],
      },
      commitMessage: I18N_UPLOAD_MODAL.commitMessage,
      createMergeRequest: true,
      file: null,
      branchName: this.patchBranchName,
    };
  },
  mounted() {
    eventHub.$on(this.openModal, this.show);
  },
  methods: {
    show() {
      this.$root.$emit('bv::show::modal', this.modalId);
    },
    async handlePrimary() {
      const options = { headers: { ...ContentTypeMultipartFormData } };
      const formData = new FormData();
      formData.append('file', this.file);
      formData.append('branch_name', this.branchName);
      formData.append('create_merge_request', this.createMergeRequest);
      formData.append('commit_message', this.commitMessage);
      const result = await axios.post(this.createBlobPath, formData, options);
      window.location.href = result.data.filePath;
    },
    saveFile(files) {
      [this.file] = files;
    },
  },
  i18n: I18N_UPLOAD_MODAL,
};
</script>

<template>
  <gl-modal
    v-bind="$attrs"
    data-testid="modal-upload"
    :modal-id="modalId"
    size="md"
    title="Upload New File"
    :action-cancel="actionCancel"
    :action-primary="actionPrimary"
    @primary="handlePrimary"
  >
    <form ref="uploadForm" class="js-quick-submit js-upload-blob-form" @submit="handlePrimary">
      <upload-dropzone
        :drop-description-message="$options.i18n.dropDescription"
        :is-file-valid="() => true"
        :valid-file-mimetypes="['*.*']"
        class="gl-h-200!"
        @change="saveFile"
      />
      <!-- <input id="file" type="file" name="file" />
      <div class="dropzone">
        <div class="dropzone-previews blob-upload-dropzone-previews">
          <p class="dz-message light">
            <gl-sprintf
              :message="
                __(`Attach a file by drag &amp; drop or %{linkStart}click to upload%{linkEnd}`)
              "
            >
              <template #link="{ content }">
                <gl-link href="#" class="markdown-selector">{{ content }}</gl-link>
              </template>
            </gl-sprintf>
          </p>
        </div>
      </div> -->
      <br />
      <div
        class="dropzone-alerts gl-alert gl-alert-danger gl-mb-5 data"
        style="display: none"
      ></div>

      <div class="form-group row commit_message-group">
        <label for="commit_message" class="col-form-label col-sm-2">{{
          $options.i18n.commitMessageLabel
        }}</label>
        <div class="col-sm-10">
          <div class="commit-message-container">
            <div class="max-width-marker"></div>
            <textarea
              id="commit_message"
              v-model="commitMessage"
              name="commit_message"
              rows="3"
              class="form-control js-commit-message"
              required
              :placeholder="$options.i18n.commitMessageLabel"
            ></textarea>
          </div>
        </div>
      </div>

      <div v-if="userPermissions.createMergeRequestIn" class="form-group row branch">
        <label for="branch_name" class="col-form-label col-sm-2">
          {{ $options.i18n.targetBranch }}
        </label>
        <div class="col-sm-10">
          <input
            id="branch_name"
            type="text"
            name="branch_name"
            class="form-control js-branch-name ref-name"
            :value="branchName"
            required
          />
          <div class="js-create-merge-request-container">
            <div class="form-check gl-mt-3">
              <input
                v-if="userPermissions.pushCode"
                id="create_merge_request"
                v-model="createMergeRequest"
                type="checkbox"
                name="create_merge_request"
                class="js-create-merge-request form-check-input"
              />
              <label for="create_merge_request" class="form-check-label">
                <gl-sprintf
                  :message="
                    __(`Start a %{strongStart}new merge request%{strongEnd} with these changes`)
                  "
                >
                  <template #strong="{ content }">
                    <strong>{{ content }}</strong>
                  </template>
                </gl-sprintf>
              </label>
            </div>
          </div>
        </div>
      </div>
      <div v-else>
        <input v-model="branchName" type="hidden" name="branch_name" />
        <input
          v-if="!userPermissions.pushCode"
          v-model="createMergeRequest"
          type="hidden"
          name="create_merge_request"
        />
      </div>
      <input type="hidden" name="original_branch" :value="refBranch" class="js-original-branch" />
    </form>
  </gl-modal>
</template>
