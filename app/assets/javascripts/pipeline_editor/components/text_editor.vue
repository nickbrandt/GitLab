<script>
import EditorLite from '~/vue_shared/components/editor_lite.vue';
import EditorCiSchemaExtension from '~/editor/editor_ci_schema_ext';

export default {
  components: {
    EditorLite,
  },
  props: {
    ciConfigPath: {
      type: String,
      required: true,
    },
    commitId: {
      type: String,
      required: false,
      default: null,
    },
    projectPath: {
      type: String,
      required: true,
    },
  },
  methods: {
    onEditorReady(editorInstance) {
      editorInstance.use(EditorCiSchemaExtension);
      editorInstance.registerCiSchema({
        fileName: this.ciConfigPath,
        projectPath: this.projectPath,
        ref: this.commitId,
      });
    },
  },
};
</script>
<template>
  <div class="gl-border-solid gl-border-gray-100 gl-border-1">
    <editor-lite
      :file-name="ciConfigPath"
      v-bind="$attrs"
      v-on="$listeners"
      @editor-ready="onEditorReady"
    />
  </div>
</template>
