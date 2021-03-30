<script>
import { GlForm, GlFormInput, GlFormInputGroup, GlButton, GlIcon } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { VALID_CORPUS_MIMETYPE } from '../constants';
import uploadCorpus from '../graphql/mutations/upload_corpus.mutation.graphql';

export default {
  components: {
    GlForm,
    GlFormInput,
    GlFormInputGroup,
    GlButton,
    GlIcon,
  },
  i18n: {
    uploadButtonText: __('Choose File...'),
    uploadMessage: s__('CorpusManagement|New corpus needs to be a upload in *.zip format. Maximum 10Gib')
  },
  props: {
  },
  computed: {
    hasAttachment() {
      return Boolean(this.attachmentName);
    }
  },
  data() {
    return {
      isStagedForUpload: false,
      isUploading: false,
      attachmentName: '',
      files: [],
    }
  },
  methods: {
    openFileUpload() {
      this.$refs.fileUpload.click();
    },
    beginFileUpload() {
      this.$apollo.mutate({
        mutation: uploadCorpus,
        variables: { name, projectPath: this.projectFullPath },
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
    <gl-form-input-group class="gl-corpus-name">
      <slot name="input">
        <gl-form-input
          ref="input"
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
        aria-label="Clear"
      />

    </gl-form-input-group>

    <gl-form-input-group 
      label="Corpus file"
      label-size="sm"
    >
  
      <template v-if="hasAttachment">
        {{ this.attachmentName }}
        <gl-icon name="close" />
      </template>

      <gl-button
        v-else
        @click="openFileUpload"
      >
        {{ this.$options.i18n.uploadButtonText }}
      </gl-button>

      <input
        ref="fileUpload"
        type="file"
        name="corpus_file"
        :accept="$options.VALID_CORPUS_MIMETYPE.mimetype"
        class="gl-display-none"
        @change="onFileUploadChange"
      />


      <span>{{ this.$options.i18n.uploadMessage }}</span>

      <gl-button 
        v-if="hasAttachment" variant="success"
        @click="beginFileUpload"
      >
        {{ __('Upload file') }}
      </gl-button>  

    </gl-form-input-group>

  </gl-form>
</template>
