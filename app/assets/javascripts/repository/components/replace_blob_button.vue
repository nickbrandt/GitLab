<script>
import { GlButton, GlModalDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import UploadBlobModal from '~/repository/components/upload_blob_modal.vue';

const REPLACE_BLOB_MODAL_ID = 'modal-upload-blob';

export default {
  components: {
    GlButton,
    UploadBlobModal,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  inject: {
    targetBranch: {
      default: '',
    },
    originalBranch: {
      default: '',
    },
    canPushCode: {
      default: false,
    },
    path: {
      default: '',
    },
    projectPath: {
      default: '',
    },
    commitMessage: {
      default: __('Upload New File'),
    },
    modalTitle: {
      default: null,
    },
  },
  replaceBlobModalId: REPLACE_BLOB_MODAL_ID,
};
</script>
<template>
  <span>
    <gl-button
      v-gl-modal="$options.replaceBlobModalId"
      class="gl-rounded-0!"
      data-testid="upload-file-button"
      >{{  __('Replace'), }}</gl-button
    >
    <upload-blob-modal
      :modal-id="$options.replaceBlobModalId"
      :commit-message="commitMessage"
      :target-branch="targetBranch"
      :original-branch="originalBranch"
      :can-push-code="canPushCode"
      :path="path"
      :title="modalTitle"
      :upload-button-text="__('Replace file')"
    />
  </span>
</template>
