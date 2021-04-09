<script>
import { GlForm, GlFormInput, GlFormInputGroup, GlButton, GlIcon, GlLoadingIcon, GlFormGroup } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { VALID_CORPUS_MIMETYPE } from '../constants';
import uploadCorpus from '../graphql/mutations/upload_corpus.mutation.graphql';
import resetCorpus from '../graphql/mutations/reset_corpus.mutation.graphql';
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
  inject: ['projectFullPath','corpusHelpPath'],
  i18n: {
    uploadButtonText: __('Choose File...'),
    uploadMessage: s__('CorpusManagement|New corpus needs to be a upload in *.zip format. Maximum 10Gib')
  },
  props: {
  },
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
  computed: {
    hasAttachment() {
      return Boolean(this.attachmentName);
    },
    isShowingAttatchmentName() {
      return this.hasAttachment && !this.isLoading
    },
    isUploading() {
      return this.states?.uploadState.isUploading;
    },
    isUploaded() {
      return this.states?.uploadState.progress === 100;
    },
    showUploadButton() {
      return this.hasAttachment && !this.isUploading && !this.isUploaded
    },
    showFilePickerButton() {
      return !this.isUploaded;
    },
    progress() {
      return this.states?.uploadState.progress;
    },
  },
  data() {
    return {
      attachmentName: '',
      corpusName: '',
      files: [],
      uploadTimeout: null,
    }
  },
  methods: {
    clearName() {
      this.corpusName = '';
    },
    resetAttatchment(){
      this.$refs.fileUpload.value = null;
      this.attachmentName = '';
      this.files = [];
    },
    cancelUpload(){
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
      this.$apollo.mutate({
        mutation: uploadCorpus,
        variables: { name: this.corpusName, projectPath: this.projectFullPath },
      }).then(({data})=>{
        if(data.uploadCorpus<100){
          component.uploadTimeout = setTimeout(()=>{
              uploadCallback();
            },500)
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
    <gl-form-group
      label="Corpus name"
      label-size="sm"
      label-for="corpus-name"
    >
      <gl-form-input-group class="gl-corpus-name">

        <slot name="input">
          <gl-form-input
            ref="input"
            id="corpus-name"
            v-model="corpusName"
          />
        </slot>

        <gl-button
          @click="clearName"
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

    </gl-form-group>

    <gl-form-group
      label="Corpus name"
      label-size="sm"
      label-for="corpus-file"
    >
      <gl-form-input-group 
        id='corpus-file'
        class="gl-display-flex gl-align-items-center"
      >
    
        <gl-button
          v-if="showFilePickerButton"
          @click="openFileUpload"
          :disabled="isUploading"
        >
          {{ this.$options.i18n.uploadButtonText }}
        </gl-button>

        <span class="foo" v-if="isShowingAttatchmentName">
          {{ this.attachmentName }}
          <gl-icon v-if="!isUploaded" @click="resetAttatchment" name="close" />
        </span>

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
          v-if="showUploadButton" variant="success"
          @click="beginFileUpload"
        >
          {{ __('Upload file') }}
        </gl-button>  

        <div v-if="isUploading">
          <gl-loading-icon inline size="sm" /> Attatching File - {{ progress }} %
          <gl-button @click="cancelUpload" size="small"> {{ __('Cancel') }} </gl-button>
        </div>


      </gl-form-input-group>      

    </gl-form-group>

  </gl-form>
</template>
