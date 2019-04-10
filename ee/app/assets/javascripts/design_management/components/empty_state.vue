<script>
import UploadButton from './upload/button.vue';

export default {
  components: {
    UploadButton,
  },
  props: {
    canUploadDesign: {
      type: Boolean,
      required: true,
    },
    isSaving: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    onFileUploadChange(files) {
      this.$emit('upload', files);
    },
  },
};
</script>

<template>
  <div class="empty-state row">
    <div class="col-12">
      <div class="text-content">
        <h4 class="center">
          {{ s__('DesignManagement|The one place for your designs') }}
        </h4>
        <p>
          {{
            s__(`DesignManagement|Upload and view the latest designs for this issue.
            Consistent and easy to find, so everyone is up to date.`)
          }}
        </p>
        <div v-if="canUploadDesign" class="center">
          <upload-button :is-saving="isSaving" @upload="onFileUploadChange" />
        </div>
      </div>
    </div>
  </div>
</template>
