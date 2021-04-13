<script>
import { GlButton, GlModal, GlModalDirective } from '@gitlab/ui';
import CorpusUploadModal from 'ee/security_configuration/corpus_management/components/corpus_upload_modal.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { s__ } from '~/locale';
import addCorpusMutation from '../graphql/mutations/add_corpus.mutation.graphql';
import resetCorpus from '../graphql/mutations/reset_corpus.mutation.graphql';
import getCorpusesQuery from '../graphql/queries/get_corpuses.query.graphql';

export default {
  components: {
    GlButton,
    GlModal,
    CorpusUploadModal,
  },
  directives: {
    GlModalDirective,
  },
  i18n: {
    totalSize: s__('CorpusManagement|Total Size:'),
    newUpload: s__('CorpusManagement|New upload'),
    newCorpus: s__('CorpusMnagement|New corpus'),
  },
  inject: ['projectFullPath', 'corpusHelpPath'],
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
    },
  },
  modal: {
    actionCancel: {
      text: s__('Cancel'),
    },
    modalId: 'corpus-upload-modal',
  },
  props: {
    totalSize: {
      type: Number,
      required: true,
    },
  },
  computed: {
    formattedFileSize() {
      return numberToHumanSize(this.totalSize);
    },
    isUploaded() {
      return this.states?.uploadState.progress === 100;
    },
    variant() {
      return this.isUploaded ? 'confirm' : 'default';
    },
    actionPrimaryProps() {
      return {
        text: s__('Add'),
        attributes: {
          'data-testid': 'modal-confirm',
          disabled: !this.isUploaded,
          variant: this.variant,
        },
      };
    },
  },
  methods: {
    addCorpus() {
      this.$apollo.mutate({
        mutation: addCorpusMutation,
        variables: { name: this.$options.i18n.newCorpus, projectPath: this.projectFullPath },
      });
    },
    resetCorpus() {
      this.$apollo.mutate({
        mutation: resetCorpus,
        variables: { name: '', projectPath: this.projectFullPath },
      });
    },
  },
};
</script>
<template>
  <div
    class="gl-h-11 gl-bg-gray-10 gl-display-flex gl-justify-content-space-between gl-align-items-center"
  >
    <div class="gl-ml-5">
      {{ s__('CorpusManagement|Total Size:') }}
      <span class="gl-font-weight-bold">{{ formattedFileSize }}</span>
    </div>

    <gl-button v-gl-modal-directive="$options.modal.modalId" class="gl-mr-5" variant="confirm">
      {{ this.$options.i18n.newCorpus }}
    </gl-button>

    <gl-modal
      :modal-id="$options.modal.modalId"
      :title="$options.i18n.newCorpus"
      size="sm"
      :action-primary="actionPrimaryProps"
      :action-cancel="$options.modal.actionCancel"
      @primary="addCorpus"
      @canceled="resetCorpus"
    >
      <corpus-upload-modal />
    </gl-modal>
  </div>
</template>
