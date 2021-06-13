import { GlAlert } from '@gitlab/ui';
import { EditorContent } from '@tiptap/vue-2';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContentEditor from '~/content_editor/components/content_editor.vue';
import TopToolbar from '~/content_editor/components/top_toolbar.vue';
import { createContentEditor } from '~/content_editor/services/create_content_editor';

describe('ContentEditor', () => {
  let wrapper;
  let editor;

  const findEditorElement = () => wrapper.findByTestId('content-editor');

  const createWrapper = async (contentEditor) => {
    wrapper = shallowMountExtended(ContentEditor, {
      propsData: {
        contentEditor,
      },
    });
  };

  beforeEach(() => {
    editor = createContentEditor({ renderMarkdown: () => true });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders editor content component and attaches editor instance', () => {
    createWrapper(editor);

    const editorContent = wrapper.findComponent(EditorContent);

    expect(editorContent.props().editor).toBe(editor.tiptapEditor);
    expect(editorContent.classes()).toContain('md');
  });

  it('renders top toolbar component and attaches editor instance', () => {
    createWrapper(editor);

    expect(wrapper.findComponent(TopToolbar).props().contentEditor).toBe(editor);
  });

  describe('if an error is emitted by the top toolbar', () => {
    beforeEach(async () => {
      createWrapper(editor);

      return wrapper.findComponent(TopToolbar).vm.$emit('error', 'An error occured');
    });

    it('shows an error alert', () => {
      expect(wrapper.findComponent(GlAlert).text()).toContain('An error occured');
    });

    it('hides the error alert on dismiss', async () => {
      await wrapper.findComponent(GlAlert).vm.$emit('dismiss');

      expect(wrapper.findComponent(GlAlert).exists()).toBe(false);
    });
  });

  it.each`
    isFocused | classes
    ${true}   | ${['md-area', 'is-focused']}
    ${false}  | ${['md-area']}
  `(
    'has $classes class selectors when tiptapEditor.isFocused = $isFocused',
    ({ isFocused, classes }) => {
      editor.tiptapEditor.isFocused = isFocused;
      createWrapper(editor);

      expect(findEditorElement().classes()).toStrictEqual(classes);
    },
  );

  it('adds isFocused class when tiptapEditor is focused', () => {
    editor.tiptapEditor.isFocused = true;
    createWrapper(editor);

    expect(findEditorElement().classes()).toContain('is-focused');
  });
});
