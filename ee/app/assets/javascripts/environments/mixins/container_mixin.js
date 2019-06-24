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
    deployBoardsHelpPath: {
      type: String,
      required: false,
      default: '',
    },
  },
};
