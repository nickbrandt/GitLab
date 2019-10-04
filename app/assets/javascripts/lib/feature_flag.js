export default class {
  static isEnabled(featureName) {
    return gon && gon.features && gon.features[featureName];
  }
}
