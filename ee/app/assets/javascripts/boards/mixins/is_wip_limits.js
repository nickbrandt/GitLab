export default {
  computed: {
    isWipLimitsOn() {
      return gon.features.wipLimits;
    },
  },
};
