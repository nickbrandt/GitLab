import Vuex from 'vuex';
import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import { shallowMount } from '@vue/test-utils';
import { editor as monacoEditor } from 'monaco-editor';
import '~/behaviors/markdown/render_gfm';
import axios from '~/lib/utils/axios_utils';
import EditorLite from '~/editor/editor_lite';
import ModelManager from '~/ide/lib/common/model_manager';
import waitForPromises from 'helpers/wait_for_promises';
import { createStoreOptions } from '~/ide/stores';
import RepoEditor from '~/ide/components/repo_editor.vue';
import ContentViewer from '~/vue_shared/components/content_viewer/content_viewer.vue';
import { EditorWebIdeExtension } from '~/editor/extensions/editor_lite_webide_ext';
import {
  leftSidebarViews,
  FILE_VIEW_MODE_EDITOR,
  FILE_VIEW_MODE_PREVIEW,
  viewerTypes,
} from '~/ide/constants';
import { file } from '../helpers';

const defaultFileProps = {
  ...file('file.txt'),
  content: 'hello world',
  active: true,
  tempFile: true,
};
const createActiveFle = (props) => {
  return {
    ...defaultFileProps,
    ...props,
  };
};
const storeActions = {
  getFileData: jest.fn().mockReturnValue(Promise.resolve({})),
  getRawFileData: jest.fn().mockReturnValue(Promise.resolve('')),
};

const prepareStore = (state, activeFile) => {
  const localState = {
    openFiles: [activeFile],
    projects: {
      'gitlab-org/gitlab': {
        branches: {
          master: {
            name: 'master',
            commit: {
              id: 'abcdefgh',
            },
          },
        },
      },
    },
    currentProjectId: 'gitlab-org/gitlab',
    currentBranchId: 'master',
    entries: {
      [activeFile.path]: activeFile,
    },
  };
  const storeOptions = createStoreOptions();
  return new Vuex.Store({
    ...createStoreOptions(),
    state: {
      ...storeOptions.state,
      ...localState,
      ...state,
    },
    actions: {
      ...storeOptions.actions,
      ...storeActions,
    },
  });
};

describe('RepoEditor', () => {
  let wrapper;
  let createInstanceSpy;
  let createDiffInstanceSpy;
  let createModelSpy;

  const createComponent = async ({ state = {}, activeFile = defaultFileProps } = {}) => {
    const store = prepareStore(state, activeFile);
    wrapper = shallowMount(RepoEditor, {
      store,
      propsData: {
        file: store.state.openFiles[0],
      },
      mocks: {
        ContentViewer,
      },
    });
    await waitForPromises();
  };

  const findEditor = () => wrapper.find('.multi-file-editor-holder');
  const findTabs = () => wrapper.findAll('.ide-mode-tabs .nav-links li');

  beforeEach(() => {
    createInstanceSpy = jest.spyOn(EditorLite.prototype, 'createInstance');
    createDiffInstanceSpy = jest.spyOn(EditorLite.prototype, 'createDiffInstance');
    createModelSpy = jest.spyOn(monacoEditor, 'createModel');
  });

  afterEach(() => {
    jest.clearAllMocks();
    // eslint-disable-next-line no-undef
    monaco.editor.getModels().forEach((model) => model.dispose());
    wrapper.destroy();
    wrapper = null;
  });

  describe('default', () => {
    it.each`
      boolVal  | textVal
      ${true}  | ${'all'}
      ${false} | ${'none'}
    `('sets renderWhitespace to "$textVal"', async ({ boolVal, textVal } = {}) => {
      await createComponent({
        state: {
          renderWhitespaceInCode: boolVal,
        },
      });
      expect(wrapper.vm.editorOptions.renderWhitespace).toEqual(textVal);
    });

    it('renders an ide container', async () => {
      await createComponent();
      expect(findEditor().isVisible()).toBe(true);
    });

    it('renders only an edit tab', async () => {
      await createComponent();
      const tabs = findTabs();

      expect(tabs.length).toBe(1);
      expect(tabs.at(0).text()).toBe('Edit');
    });
  });

  describe('when file is markdown', () => {
    const content = 'testing 123';
    let mock;
    let activeFile;

    beforeEach(() => {
      activeFile = createActiveFle({
        projectId: 'namespace/project',
        path: 'sample.md',
        name: 'sample.md',
        content,
      });

      mock = new MockAdapter(axios);

      mock.onPost(/(.*)\/preview_markdown/).reply(200, {
        body: `<p>${content}</p>`,
      });
    });

    afterEach(() => {
      mock.restore();
    });

    it('renders an Edit and a Preview Tab', async () => {
      await createComponent({ activeFile });
      const tabs = findTabs();

      expect(tabs.length).toBe(2);
      expect(tabs.at(0).text()).toBe('Edit');
      expect(tabs.at(1).text()).toBe('Preview Markdown');
    });

    it('renders markdown for tempFile', async () => {
      await createComponent({ activeFile });

      wrapper.find('[data-testid="preview-tab"]').trigger('click');
      await waitForPromises();
      expect(wrapper.find(ContentViewer).html()).toContain(content);
    });

    it('shows no tabs when not in Edit mode', async () => {
      await createComponent({
        state: {
          currentActivityView: leftSidebarViews.review.name,
        },
        activeFile,
      });
      expect(findTabs()).toHaveLength(0);
    });
  });

  describe('when file is binary and not raw', () => {
    beforeEach(async () => {
      const activeFile = createActiveFle({
        name: 'file.dat',
        content: '🐱', // non-ascii binary content
      });
      await createComponent({ activeFile });
    });

    it('does not render the IDE', () => {
      expect(findEditor().isVisible()).toBe(false);
    });

    it('does not create an instance', () => {
      expect(createInstanceSpy).not.toHaveBeenCalled();
      expect(createDiffInstanceSpy).not.toHaveBeenCalled();
    });
  });

  describe('createEditorInstance', () => {
    it.each`
      viewer              | diffInstance
      ${viewerTypes.edit} | ${undefined}
      ${viewerTypes.diff} | ${true}
      ${viewerTypes.mr}   | ${true}
    `(
      'creates instance of correct type when viewer is $viewer',
      async ({ viewer, diffInstance }) => {
        await createComponent({
          state: { viewer },
        });
        const isDiff = () => {
          return diffInstance ? { isDiff: true } : {};
        };
        expect(createInstanceSpy).toHaveBeenCalledWith(expect.objectContaining(isDiff()));
        expect(createDiffInstanceSpy).toHaveBeenCalledTimes((diffInstance && 1) || 0);
      },
    );

    it('installs the WebIDE extension', async () => {
      const extensionSpy = jest.spyOn(EditorLite, 'instanceApplyExtension');
      await createComponent();
      expect(extensionSpy).toHaveBeenCalled();
      Reflect.ownKeys(EditorWebIdeExtension.prototype)
        .filter((fn) => fn !== 'constructor')
        .forEach((fn) => {
          expect(wrapper.vm.editor[fn]).toBe(EditorWebIdeExtension.prototype[fn]);
        });
    });
  });

  describe('setupEditor', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('creates new model on load', () => {
      // We always create two models per file to be able to build a diff of changes
      expect(createModelSpy).toHaveBeenCalledTimes(2);
      // The model with the most recent changes is the last one
      const [content] = createModelSpy.mock.calls[1];
      expect(content).toBe(defaultFileProps.content);
    });

    it('does not create a new model on subsequent calls to setupEditor and re-uses the already-existing model', () => {
      const existingModel = wrapper.vm.model;
      createModelSpy.mockClear();

      wrapper.vm.setupEditor();

      expect(createModelSpy).not.toHaveBeenCalled();
      expect(wrapper.vm.model).toBe(existingModel);
    });

    it('adds callback methods', () => {
      jest.spyOn(wrapper.vm.editor, 'onPositionChange');
      jest.spyOn(wrapper.vm.model, 'onChange');
      jest.spyOn(wrapper.vm.model, 'updateOptions');

      wrapper.vm.setupEditor();

      expect(wrapper.vm.editor.onPositionChange).toHaveBeenCalledTimes(1);
      expect(wrapper.vm.model.onChange).toHaveBeenCalledTimes(1);
      expect(wrapper.vm.model.updateOptions).toHaveBeenCalledWith(wrapper.vm.rules);
    });

    it('updates state with the value of the model', () => {
      const newContent = 'As Gregor Samsa\n awoke one morning\n';
      wrapper.vm.model.setValue(newContent);

      wrapper.vm.setupEditor();

      expect(wrapper.vm.file.content).toBe(newContent);
    });

    it('sets head model as staged file', () => {
      wrapper.vm.modelManager.dispose();
      const addModelSpy = jest.spyOn(ModelManager.prototype, 'addModel');

      wrapper.vm.$store.state.stagedFiles.push({ ...wrapper.vm.file, key: 'staged' });
      wrapper.vm.file.staged = true;
      wrapper.vm.file.key = `unstaged-${wrapper.vm.file.key}`;

      wrapper.vm.setupEditor();

      expect(addModelSpy).toHaveBeenCalledWith(
        wrapper.vm.file,
        wrapper.vm.$store.state.stagedFiles[0],
      );
    });
  });

  describe('editor updateDimensions', () => {
    let updateDimensionsSpy;
    let updateDiffViewSpy;
    beforeEach(async () => {
      await createComponent();
      updateDimensionsSpy = jest.spyOn(wrapper.vm.editor, 'updateDimensions');
      updateDiffViewSpy = jest.spyOn(wrapper.vm.editor, 'updateDiffView').mockImplementation();
    });

    it('calls updateDimensions only when panelResizing is false', async () => {
      expect(updateDimensionsSpy).not.toHaveBeenCalled();
      expect(updateDiffViewSpy).not.toHaveBeenCalled();
      expect(wrapper.vm.$store.state.panelResizing).toBe(false); // default value

      wrapper.vm.$store.state.panelResizing = true;
      await wrapper.vm.$nextTick();

      expect(updateDimensionsSpy).not.toHaveBeenCalled();
      expect(updateDiffViewSpy).not.toHaveBeenCalled();

      wrapper.vm.$store.state.panelResizing = false;
      await wrapper.vm.$nextTick();

      expect(updateDimensionsSpy).toHaveBeenCalledTimes(1);
      expect(updateDiffViewSpy).toHaveBeenCalledTimes(1);

      wrapper.vm.$store.state.panelResizing = true;
      await wrapper.vm.$nextTick();

      expect(updateDimensionsSpy).toHaveBeenCalledTimes(1);
      expect(updateDiffViewSpy).toHaveBeenCalledTimes(1);
    });

    it('calls updateDimensions when rightPane is toggled', async () => {
      expect(updateDimensionsSpy).not.toHaveBeenCalled();
      expect(updateDiffViewSpy).not.toHaveBeenCalled();
      expect(wrapper.vm.$store.state.rightPane.isOpen).toBe(false); // default value

      wrapper.vm.$store.state.rightPane.isOpen = true;
      await wrapper.vm.$nextTick();

      expect(updateDimensionsSpy).toHaveBeenCalledTimes(1);
      expect(updateDiffViewSpy).toHaveBeenCalledTimes(1);

      wrapper.vm.$store.state.rightPane.isOpen = false;
      await wrapper.vm.$nextTick();

      expect(updateDimensionsSpy).toHaveBeenCalledTimes(2);
      expect(updateDiffViewSpy).toHaveBeenCalledTimes(2);
    });
  });

  describe('editor tabs', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it.each`
      mode        | isVisible
      ${'edit'}   | ${true}
      ${'review'} | ${false}
      ${'commit'} | ${false}
    `('tabs in $mode are $isVisible', async ({ mode, isVisible } = {}) => {
      wrapper.vm.$store.state.currentActivityView = leftSidebarViews[mode].name;

      await wrapper.vm.$nextTick();
      expect(wrapper.find('.nav-links').exists()).toBe(isVisible);
    });
  });

  describe('files in preview mode', () => {
    let updateDimensionsSpy;
    const changeViewMode = (viewMode) =>
      wrapper.vm.$store.dispatch('editor/updateFileEditor', {
        path: wrapper.vm.file.path,
        data: { viewMode },
      });

    beforeEach(async () => {
      await createComponent({
        activeFile: createActiveFle({
          name: 'myfile.md',
          content: 'hello world',
        }),
      });

      updateDimensionsSpy = jest.spyOn(wrapper.vm.editor, 'updateDimensions');

      changeViewMode(FILE_VIEW_MODE_PREVIEW);
      await wrapper.vm.$nextTick();
    });

    it('do not show the editor', () => {
      expect(wrapper.vm.showEditor).toBe(false);
      expect(findEditor().isVisible()).toBe(false);
    });

    it('updates dimensions when switching view back to edit', async () => {
      expect(updateDimensionsSpy).not.toHaveBeenCalled();

      changeViewMode(FILE_VIEW_MODE_EDITOR);
      await wrapper.vm.$nextTick();

      expect(updateDimensionsSpy).toHaveBeenCalled();
    });
  });

  describe('initEditor', () => {
    const hideEditorAndRunFn = async () => {
      jest.clearAllMocks();
      jest.spyOn(wrapper.vm, 'shouldHideEditor', 'get').mockReturnValue(true);

      wrapper.vm.initEditor();
      await wrapper.vm.$nextTick();
    };

    it('does not fetch file information for temp entries', async () => {
      await createComponent({
        activeFile: createActiveFle({
          tempFile: true,
        }),
      });

      expect(storeActions.getFileData).not.toHaveBeenCalled();
    });

    it('is being initialised for files without content even if shouldHideEditor is `true`', async () => {
      await createComponent({
        activeFile: createActiveFle({
          tempFile: false,
          content: '',
          raw: '',
        }),
      });

      await hideEditorAndRunFn();

      expect(storeActions.getFileData).toHaveBeenCalled();
      expect(storeActions.getRawFileData).toHaveBeenCalled();
    });

    it('does not initialize editor for files already with content when shouldHideEditor is `true`', async () => {
      await createComponent({
        activeFile: createActiveFle({
          tempFile: false,
          content: 'foo',
        }),
      });

      await hideEditorAndRunFn();

      expect(storeActions.getFileData).not.toHaveBeenCalled();
      expect(storeActions.getRawFileData).not.toHaveBeenCalled();
      expect(createInstanceSpy).not.toHaveBeenCalled();
    });
  });

  describe('updates on file changes', () => {
    beforeEach(async () => {
      await createComponent({
        activeFile: createActiveFle({
          content: 'foo', // need to prevent full cycle of initEditor
        }),
      });
      jest.spyOn(wrapper.vm, 'initEditor').mockImplementation();
    });

    it('calls removePendingTab when old file is pending', async () => {
      jest.spyOn(wrapper.vm, 'shouldHideEditor', 'get').mockReturnValue(true);
      jest.spyOn(wrapper.vm, 'removePendingTab').mockImplementation();

      const origFile = wrapper.vm.file;
      wrapper.vm.file.pending = true;
      await wrapper.vm.$nextTick();

      wrapper.setProps({
        file: file('testing'),
      });
      wrapper.vm.file.content = 'foo'; // need to prevent full cycle of initEditor
      await wrapper.vm.$nextTick();

      expect(wrapper.vm.removePendingTab).toHaveBeenCalledWith(origFile);
    });

    it('does not call initEditor if the file did not change', async () => {
      Vue.set(wrapper.vm, 'file', wrapper.vm.file);
      await wrapper.vm.$nextTick();

      expect(wrapper.vm.initEditor).not.toHaveBeenCalled();
    });

    it('calls initEditor when file key is changed', async () => {
      expect(wrapper.vm.initEditor).not.toHaveBeenCalled();

      wrapper.setProps({
        file: {
          ...wrapper.vm.file,
          key: 'new',
        },
      });
      await wrapper.vm.$nextTick();

      expect(wrapper.vm.initEditor).toHaveBeenCalled();
    });
  });
});
