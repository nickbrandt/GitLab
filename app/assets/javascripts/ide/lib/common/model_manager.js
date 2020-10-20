import Disposable from './disposable';
import Model from './model';

export default class ModelManager {
  static instance;

  constructor() {
    this.disposable = new Disposable();
    this.models = new Map();

    ModelManager.instance = this;
  }

  hasCachedModel(key) {
    return this.models.has(key);
  }

  getModel(key) {
    return this.models.get(key);
  }

  addModel(file, head = null) {
    if (this.hasCachedModel(file.id)) {
      return this.getModel(file.id);
    }

    const model = new Model(file, head);
    this.models.set(model.path, model);
    this.disposable.add(model);

    return model;
  }

  dispose() {
    // dispose of all the models
    this.disposable.dispose();
    this.models.clear();
  }

  static updateContent(id, { content, changed }) {
    const model = ModelManager.instance.getModel(id);
    if (model) model.updateContent({ content, changed });
  }

  static updateNewContent(id, content) {
    const model = ModelManager.instance.getModel(id);
    if (model) model.updateNewContent(content);
  }

  static dispose(id) {
    const model = ModelManager.instance.getModel(id);
    if (model) model.dispose();

    ModelManager.instance.models.delete(id);
  }
}
