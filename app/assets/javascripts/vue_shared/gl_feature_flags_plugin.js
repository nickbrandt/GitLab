export default Vue => {
  Vue.mixin({
    provide: {
      glFeatures: { ...(window.gon.features || {}) },
    },
  });
};
