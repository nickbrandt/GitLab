<script>
import { initEditorLite } from '~/blob/utils';
import { debounce } from 'lodash';
import {
  SNIPPET_MARK_BLOB_CONTENT,
  SNIPPET_MARK_EDIT_APP_START,
  SNIPPET_MEASURE_BLOB_CONTENT,
  SNIPPET_MEASURE_BLOB_CONTENT_WITHIN_APP,
} from '~/performance_constants';

export default {
  props: {
    value: {
      type: String,
      required: false,
      default: '',
    },
    fileName: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      editor: null,
    };
  },
  watch: {
    fileName(newVal) {
      this.editor.updateModelLanguage(newVal);
    },
  },
  mounted() {
    this.editor = initEditorLite({
      el: this.$refs.editor,
      blobPath: this.fileName,
      blobContent: this.value,
    });
    window.requestAnimationFrame(() => {
      performance.mark(SNIPPET_MARK_BLOB_CONTENT);
      performance.measure(SNIPPET_MEASURE_BLOB_CONTENT);
      performance.measure(SNIPPET_MEASURE_BLOB_CONTENT_WITHIN_APP, SNIPPET_MARK_EDIT_APP_START);
    });
  },
  methods: {
    triggerFileChange: debounce(function debouncedFileChange() {
      this.$emit('input', this.editor.getValue());
    }, 250),
  },
};
</script>
<template>
  <div class="file-content code">
    <pre id="editor" ref="editor" data-editor-loading @keyup="triggerFileChange">{{ value }}</pre>
  </div>
</template>
