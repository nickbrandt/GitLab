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
    onEditorReady() {
      const editorInstance = this.$refs.editor.getEditor();
      editorInstance.use(EditorCiSchemaExtension);
      editorInstance.registerCiSchema({
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
      ref="editor"
      :file-name="ciConfigPath"
      v-bind="$attrs"
      v-on="$listeners"
      @editor-ready="onEditorReady"
    />
  </div>
</template>
