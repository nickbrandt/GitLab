<script>
import { GlButton, GlModal, GlModalDirective } from '@gitlab/ui';
import CorpusUploadModal from 'ee/security_configuration/corpus_management/components/corpus_upload_modal.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { s__ } from '~/locale';

export default {
  components: {
    GlButton,
    GlModal,
    CorpusUploadModal,
  },
  directives: {
    GlModalDirective,
  },
  modal: {
    actionPrimary: {
      text: s__('Add'),
      attributes: { variant: 'danger', 'data-testid': 'modal-confirm' },
    },
    actionCancel: {
      text: s__('Cancel'),
    },
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

    <gl-button class="gl-mr-5" variant="success" v-gl-modal-directive="`corpus-upload-modal`">
      {{ s__('CorpusManagement|New corpus') }}
    </gl-button>  

    <gl-modal
      modal-id="corpus-upload-modal"
      title="New corpus"
      size="sm"
      :action-primary="$options.modal.actionPrimary"
      :action-cancel="$options.modal.actionCancel"      
    >
      <corpus-upload-modal 
      />
    </gl-modal> 

  </div>
</template>
