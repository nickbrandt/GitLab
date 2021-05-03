<script>
import { debounce } from 'lodash';
import { ContentEditor } from '../services/content_editor';

export default {
  props: {
    contentEditor: {
      type: ContentEditor,
      required: true,
    },
    extensions: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      editorState: {
        isFocused: false,
        toolbar: {},
      },
    };
  },
  created() {
    window.tiptapEditor = this.contentEditor.tiptapEditor;
    this.onEditorTransaction = debounce(({ editor }) => this.updateEditorState(editor), 100);

    this.updateEditorState(this.contentEditor.tiptapEditor);

    this.contentEditor.tiptapEditor.on('transaction', this.onEditorTransaction);
  },
  beforeDestroy() {
    this.contentEditor.tiptapEditor.off('transaction', this.onEditorTransaction);
  },
  methods: {
    updateEditorState(editor) {
      this.editorState.isFocused = editor.isFocused;

      this.extensions.forEach(({ setReactiveState }) => setReactiveState(editor, this.editorState));
    },
  },
  render() {
    return this.$scopedSlots.default(this.editorState);
  },
};
</script>
