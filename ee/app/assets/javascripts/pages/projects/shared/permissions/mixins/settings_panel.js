export default {
  props: {
    packagesAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    packagesHelpPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      packagesEnabled: true,
    };
  },
};
