import { isEE } from '~/lib/utils/common_utils';

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
  computed: {
    isEE() {
      return isEE();
    },
  },
  data() {
    return {
      packagesEnabled: true,
    };
  },
};
