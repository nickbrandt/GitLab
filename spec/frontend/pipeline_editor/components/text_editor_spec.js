import { nextTick } from 'vue';
import { shallowMount, mount } from '@vue/test-utils';
import EditorLite from '~/vue_shared/components/editor_lite.vue';
import EditorCiSchemaExtension from '~/editor/editor_ci_schema_ext';
import TextEditor from '~/pipeline_editor/components/text_editor.vue';

import {
  mockCiYml,
  mockCiConfigPath,
  mockProjectPath,
  mockProjectNamespace,
  mockCommitId,
} from '../mock_data';

jest.mock('~/editor/editor_ci_schema_ext');

describe('~/pipeline_editor/components/text_editor.vue', () => {
  let wrapper;
  const editorReadyListener = jest.fn();

  const createComponent = ({ props = {}, attrs = {} } = {}, mountFn = shallowMount) => {
    wrapper = mountFn(TextEditor, {
      provide: {
        projectPath: mockProjectPath,
        projectNamespace: mockProjectNamespace,
      },
      propsData: {
        ciConfigPath: mockCiConfigPath,
        commitId: mockCommitId,
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

  const findEditorLite = () => wrapper.find(EditorLite);

  it('contains an editor', () => {
    expect(findEditorLite().exists()).toBe(true);
  });

  it('editor contains the value provided', () => {
    expect(findEditorLite().props('value')).toBe(mockCiYml);
  });

  it('editor is configured for .yml', () => {
    expect(findEditorLite().props('fileName')).toBe(mockCiConfigPath);
  });

  it('bubbles up editor-ready event', () => {
    createComponent({}, mount);

    findEditorLite().vm.$emit('editor-ready');

    expect(editorReadyListener).toHaveBeenCalled();
  });

  it('registers ci schema extension', async () => {
    createComponent({}, mount);

    await nextTick();

    expect(EditorCiSchemaExtension.registerCiSchema).toHaveBeenCalledWith({
      projectPath: mockProjectPath,
      projectNamespace: mockProjectNamespace,
      ref: mockCommitId,
    });
  });
});
