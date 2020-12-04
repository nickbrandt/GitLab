import { shallowMount } from '@vue/test-utils';
import EditorLite from '~/vue_shared/components/editor_lite.vue';
import EditorCiSchemaExtension from '~/editor/editor_ci_schema_ext';
import TextEditor from '~/pipeline_editor/components/text_editor.vue';

import { mockCiYml, mockCiConfigPath, mockProjectPath } from '../mock_data';

describe('~/pipeline_editor/components/text_editor.vue', () => {
  let wrapper;
  let editorInstance;
  const editorReadyListener = jest.fn();

  const createComponent = ({ props = {}, attrs = {} } = {}, mountFn = shallowMount) => {
    editorInstance = {
      use: jest.fn(),
      registerCiSchema: jest.fn(),
    };

    wrapper = mountFn(TextEditor, {
      propsData: {
        ciConfigPath: mockCiConfigPath,
        projectPath: mockProjectPath,
        ...props,
      },
      attrs: {
        value: mockCiYml,
        ...attrs,
      },
      listeners: {
        'editor-ready': editorReadyListener,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findEditor = () => wrapper.find(EditorLite);

  it('contains an editor', () => {
    expect(findEditor().exists()).toBe(true);
  });

  it('editor contains the value provided', () => {
    expect(findEditor().props('value')).toBe(mockCiYml);
  });

  it('editor is configured for .yml', () => {
    expect(findEditor().props('fileName')).toBe(mockCiConfigPath);
  });

  it('bubbles up events', () => {
    findEditor().vm.$emit('editor-ready', editorInstance);

    expect(editorReadyListener).toHaveBeenCalled();
  });

  it('registers ci schema extension', () => {
    const mockRef = 'master';

    createComponent({
      props: {
        commitId: mockRef,
      },
    });

    findEditor().vm.$emit('editor-ready', editorInstance);

    expect(editorInstance.use).toHaveBeenCalledWith(EditorCiSchemaExtension);

    expect(editorInstance.registerCiSchema).toHaveBeenCalledWith({
      fileName: mockCiConfigPath,
      projectPath: mockProjectPath,
      ref: mockRef,
    });
  });
});
