<script>
import { GlModal, GlSprintf, GlLink } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import eventHub from '../event_hub';
import { __ } from '~/locale';
import { I18N_UPLOAD_MODAL } from '../constants';

export default {
  components: { GlModal, GlSprintf, GlLink },
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
    }
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
      commitMessage: __('Upload New File'),
    };
  },
  mounted() {
    eventHub.$on(this.openModal, this.show);
  },
  methods: {
    show() {
      this.$root.$emit('bv::show::modal', this.modalId);
    },
    handlePrimary() {
      const data = new FormData(this.$refs.uploadForm)
      axios.post(this.createBlobPath, data)
    },
    onFileInputChange(e) {
      console.log(e.target.files)
    }
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
    <form :action="createBlobPath" class="js-quick-submit js-upload-blob-form" ref="uploadForm" method="post">
      <input type="file" name="file" id="file" @change="onFileInputChange" />
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
      </div>
      <br />
      <div
        class="dropzone-alerts gl-alert gl-alert-danger gl-mb-5 data"
        style="display: none"
      ></div>

      <div class="form-group row commit_message-group">
        <label for="commit_message" class="col-form-label col-sm-2">{{
          $options.i18n.commitMessage
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
              :placeholder="$options.i18n.commitMessage"
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
            :value="refBranch"
            required
          />
          <div class="js-create-merge-request-container">
            <div class="form-check gl-mt-3">
              <input
                id="create_merge_request"
                type="checkbox"
                name="create_merge_request"
                class="js-create-merge-request form-check-input"
                checked
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
        <input type="hidden" name="branch_name" />
        <input
          v-if="!userPermissions.pushCode"
          type="hidden"
          name="create_merge_request"
          value="1"
        />
      </div>
      <input type="hidden" name="original_branch" :value="refBranch" class="js-original-branch" />
    </form>
  </gl-modal>
</template>
