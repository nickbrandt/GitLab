import { editor as monacoEditor, languages as monacoLanguages, Uri } from 'monaco-editor';
import { DEFAULT_THEME, themes } from '~/ide/lib/themes';
import languages from '~/ide/lib/languages';
import { defaultEditorOptions } from '~/ide/lib/editor_options';
import { registerLanguages } from '~/ide/utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { uuids } from '~/diffs/utils/uuids';
import { clearDomElement } from './utils';
import {
  EDITOR_LITE_INSTANCE_ERROR_NO_EL,
  URI_PREFIX,
  EDITOR_READY_EVENT,
  EDITOR_TYPE_DIFF,
} from './constants';

export default class EditorLite {
  constructor(options = {}) {
    this.instances = [];
    this.options = {
      extraEditorClassName: 'gl-editor-lite',
      ...defaultEditorOptions,
      ...options,
    };

    EditorLite.setupMonacoTheme();

    registerLanguages(...languages);
  }

  static setupMonacoTheme() {
    const themeName = window.gon?.user_color_scheme || DEFAULT_THEME;
    const theme = themes.find((t) => t.name === themeName);
    if (theme) monacoEditor.defineTheme(themeName, theme.data);
    monacoEditor.setTheme(theme ? themeName : DEFAULT_THEME);
  }

  static updateModelLanguage(path, instance) {
    if (!instance) return;
    const model = instance.getModel();
    const ext = `.${path.split('.').pop()}`;
    const language = monacoLanguages
      .getLanguages()
      .find((lang) => lang.extensions.indexOf(ext) !== -1);
    const id = language ? language.id : 'plaintext';
    monacoEditor.setModelLanguage(model, id);
  }

  static pushToImportsArray(arr, toImport) {
    arr.push(import(toImport));
  }

  static loadExtensions(extensions) {
    if (!extensions) {
      return Promise.resolve();
    }
    const promises = [];
    const extensionsArray = typeof extensions === 'string' ? extensions.split(',') : extensions;

    extensionsArray.forEach((ext) => {
      const prefix = ext.includes('/') ? '' : 'editor/';
      const trimmedExt = ext.replace(/^\//, '').trim();
      EditorLite.pushToImportsArray(promises, `~/${prefix}${trimmedExt}`);
    });

    return Promise.all(promises);
  }

  static mixIntoInstance(source, inst) {
    if (!inst) {
      return;
    }
    const isClassInstance = source.constructor.prototype !== Object.prototype;
    const sanitizedSource = isClassInstance ? source.constructor.prototype : source;
    Object.getOwnPropertyNames(sanitizedSource).forEach((prop) => {
      if (prop !== 'constructor') {
        Object.assign(inst, { [prop]: source[prop] });
      }
    });
  }

  static prepareInstance(el) {
    if (!el) {
      throw new Error(EDITOR_LITE_INSTANCE_ERROR_NO_EL);
    }

    clearDomElement(el);

    monacoEditor.onDidCreateEditor(() => {
      delete el.dataset.editorLoading;
    });
  }

  static manageDefaultExtensions(instance, el, extensions) {
    EditorLite.loadExtensions(extensions, instance)
      .then((modules) => {
        if (modules) {
          modules.forEach((module) => {
            instance.use(module.default);
          });
        }
      })
      .then(() => {
        el.dispatchEvent(new Event(EDITOR_READY_EVENT));
      })
      .catch((e) => {
        throw e;
      });
  }

  static createEditorModel({
    blobPath,
    blobContent,
    blobOriginalContent,
    blobGlobalId,
    instance,
  } = {}) {
    if (!instance) {
      return null;
    }
    const uriFilePath = joinPaths(URI_PREFIX, blobGlobalId, blobPath);
    const uri = Uri.file(uriFilePath);
    const existingModel = monacoEditor.getModel(uri);
    const model = existingModel || monacoEditor.createModel(blobContent, undefined, uri);
    if (!blobOriginalContent) {
      instance.setModel(model);
    } else {
      instance.setModel({
        original: monacoEditor.createModel(blobOriginalContent, undefined, uri),
        modified: model,
      });
    }
    return instance.getModel();
  }

  static decorateInstance = (inst) => {
    const decoratedInstance = inst;
    decoratedInstance.updateModelLanguage = (path) => EditorLite.updateModelLanguage(path, inst);
    decoratedInstance.use = (exts = []) => {
      const extensions = Array.isArray(exts) ? exts : [exts];
      extensions.forEach((extension) => {
        EditorLite.mixIntoInstance(extension, decoratedInstance);
      });
      return decoratedInstance;
    };
    return decoratedInstance;
  };

  /**
   * Creates a monaco instance with the given options.
   *
   * @param {Object} options Options used to initialize monaco.
   * @param {Element} options.el The element which will be used to create the monacoEditor.
   * @param {string} options.blobPath The path used as the URI of the model. Monaco uses the extension of this path to determine the language.
   * @param {string} options.blobContent The content to initialize the monacoEditor.
   * @param {string} options.blobGlobalId This is used to help globally identify monaco instances that are created with the same blobPath.
   */
  createInstance({
    el = undefined,
    blobPath = '',
    blobContent = '',
    blobOriginalContent = '',
    blobGlobalId = uuids()[0],
    extensions = [],
    diff = false,
    ...instanceOptions
  } = {}) {
    EditorLite.prepareInstance(el);

    let model;
    const createEditorFn = diff ? 'createDiffEditor' : 'create';
    const instance = EditorLite.decorateInstance(
      monacoEditor[createEditorFn].call(this, el, {
        ...this.options,
        ...instanceOptions,
      }),
    );

    if (instanceOptions.model !== null) {
      model = EditorLite.createEditorModel({
        blobGlobalId,
        blobOriginalContent,
        blobPath,
        blobContent,
        instance,
      });
    }

    instance.onDidDispose(() => {
      const index = this.instances.findIndex((inst) => inst === instance);
      this.instances.splice(index, 1);
      const instanceModel = instance.getModel();
      if (instanceModel) {
        if (instance.getEditorType() === EDITOR_TYPE_DIFF) {
          const { original, modified } = instanceModel;
          if (original) {
            original.dispose();
          }
          if (modified) {
            modified.dispose();
          }
        } else {
          instanceModel.dispose();
        }
      } else if (model) {
        model.dispose();
      }
    });

    EditorLite.manageDefaultExtensions(instance, el, extensions);

    this.instances.push(instance);
    return instance;
  }

  createDiffInstance(args) {
    this.createInstance({
      ...args,
      diff: true,
    });
  }

  dispose() {
    this.instances.forEach((instance) => instance.dispose());
  }

  use(exts) {
    this.instances.forEach((inst) => {
      inst.use(exts);
    });
    return this;
  }
}
