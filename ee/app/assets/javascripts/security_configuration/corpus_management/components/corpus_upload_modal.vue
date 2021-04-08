<script>
import {
  GlForm,
  GlFormInput,
  GlFormInputGroup,
  GlButton,
  GlIcon,
  GlLoadingIcon,
  GlFormGroup,
} from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { VALID_CORPUS_MIMETYPE } from '../constants';
import resetCorpus from '../graphql/mutations/reset_corpus.mutation.graphql';
import uploadCorpus from '../graphql/mutations/upload_corpus.mutation.graphql';
import getCorpusesQuery from '../graphql/queries/get_corpuses.query.graphql';

export default {
  components: {
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlLoadingIcon,
    GlFormInputGroup,
    GlButton,
    GlIcon,
  },
  inject: ['projectFullPath'],
  i18n: {
    uploadButtonText: __('Choose File...'),
    uploadMessage: s__(
      'CorpusManagement|New corpus needs to be a upload in *.zip format. Maximum 10Gib',
    ),
  },
  props: {},
  apollo: {
    states: {
      query: getCorpusesQuery,
      variables() {
        return {
          projectPath: this.projectFullPath,
          ...this.cursor,
        };
      },
      update: (data) => {
        return data;
      },
      error() {
        this.states = null;
      },
    },
  },
  data() {
    return {
      attachmentName: '',
      corpusName: '',
      files: [],
      uploadTimeout: null,
    };
  },
  computed: {
    hasAttachment() {
      return Boolean(this.attachmentName);
    },
    isShowingAttatchmentName() {
      return this.hasAttachment && !this.isLoading;
    },
    isShowingAttatchmentCancel() {
      return !this.isUploaded && !this.isUploading;
    },
    isUploading() {
      return this.states?.uploadState.isUploading;
    },
    isUploaded() {
      return this.states?.uploadState.progress === 100;
    },
    showUploadButton() {
      return this.hasAttachment && !this.isUploading && !this.isUploaded;
    },
    showFilePickerButton() {
      return !this.isUploaded;
    },
    progress() {
      return this.states?.uploadState.progress;
    },
  },
  beforeDestroy() {
    this.resetAttatchment();
    this.cancelUpload();
  },
  methods: {
    clearName() {
      this.corpusName = '';
    },
    resetAttatchment() {
      this.$refs.fileUpload.value = null;
      this.attachmentName = '';
      this.files = [];
    },
    cancelUpload() {
      clearTimeout(this.uploadTimeout);
      this.$apollo.mutate({
        mutation: resetCorpus,
        variables: { name: this.corpusName, projectPath: this.projectFullPath },
      });
    },
    openFileUpload() {
      this.$refs.fileUpload.click();
    },
    beginFileUpload() {
      const uploadCallback = this.beginFileUpload;
      const component = this;
      // Simulate incrementing file upload progress
      return this.$apollo
        .mutate({
          mutation: uploadCorpus,
          variables: { name: this.corpusName, projectPath: this.projectFullPath },
        })
        .then(({ data }) => {
          if (data.uploadCorpus < 100) {
            component.uploadTimeout = setTimeout(() => {
              uploadCallback();
            }, 500);
          }
        });
    },
    onFileUploadChange(e) {
      this.attachmentName = e.target.files[0].name;
      this.files = e.target.files;
    },
  },
  VALID_CORPUS_MIMETYPE,
};
</script>
<template>
  <gl-form>
    <gl-form-group label="Corpus name" label-size="sm" label-for="corpus-name">
      <gl-form-input-group class="gl-corpus-name">
        <slot name="input">
          <gl-form-input
            id="corpus-name"
            ref="input"
            v-model="corpusName"
            data-testid="corpus-name"
          />
        </slot>

        <gl-button
          class="gl-search-box-by-click-icon-button gl-search-box-by-click-clear-button gl-clear-icon-button"
          variant="default"
          category="tertiary"
          size="small"
          name="clear"
          title="title"
          icon="clear"
          :aria-label="__(`Clear`)"
          @click="clearName"
        />
      </gl-form-input-group>
    </gl-form-group>

    <gl-form-group label="Corpus name" label-size="sm" label-for="corpus-file">
      <gl-button
        v-if="showFilePickerButton"
        data-testid="upload-attatchment-button"
        :disabled="isUploading"
        @click="openFileUpload"
      >
        {{ this.$options.i18n.uploadButtonText }}
      </gl-button>

      <span v-if="isShowingAttatchmentName" class="gl-ml-3">
        {{ attachmentName }}
        <gl-icon v-if="isShowingAttatchmentCancel" name="close" @click="resetAttatchment" />
      </span>

      <gl-form-input-group id="corpus-file" class="gl-display-flex gl-align-items-center">
        <input
          ref="fileUpload"
          type="file"
          name="corpus_file"
          :accept="$options.VALID_CORPUS_MIMETYPE.mimetype"
          class="gl-display-none"
          @change="onFileUploadChange"
        />
      </gl-form-input-group>
    </gl-form-group>

    <span>{{ this.$options.i18n.uploadMessage }}</span>

    <gl-button
      v-if="showUploadButton"
      data-testid="upload-corpus"
      class="gl-mt-2"
      variant="success"
      @click="beginFileUpload"
    >
      {{ __('Upload file') }}
    </gl-button>

    <div v-if="isUploading" data-testid="upload-status" class="gl-mt-2">
      <gl-loading-icon inline size="sm" />
      {{ sprintf(__('Attatching File - %{progress}%'), { progress }) }}
      <gl-button size="small" @click="cancelUpload"> {{ __('Cancel') }} </gl-button>
    </div>
  </gl-form>
</template>
