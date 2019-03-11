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
  methods: {
    shouldShowCanaryCallout(env) {
      return env.showCanaryCallout && this.showCanaryDeploymentCallout;
    },
    shouldRenderDeployBoard(model) {
      return model.hasDeployBoard && model.isDeployBoardVisible;
    },
  },
};
