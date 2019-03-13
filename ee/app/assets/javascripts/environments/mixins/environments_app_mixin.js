import eventHub from '~/environments/event_hub';

export default {
  props: {
    canaryDeploymentFeatureId: {
      type: String,
      required: true,
    },
    showCanaryDeploymentCallout: {
      type: Boolean,
      required: true,
    },
    userCalloutsPath: {
      type: String,
      required: true,
    },
    lockPromotionSvgPath: {
      type: String,
      required: true,
    },
    helpCanaryDeploymentsPath: {
      type: String,
      required: true,
    },
  },

  created() {
    eventHub.$on('toggleDeployBoard', this.toggleDeployBoard);
  },

  beforeDestroy() {
    eventHub.$off('toggleDeployBoard');
  },

  methods: {
    /**
     * Toggles the visibility of the deploy boards of the clicked environment.
     * @param {Object} model
     */
    toggleDeployBoard(model) {
      this.store.toggleDeployBoard(model.id);
    },
  },
};
