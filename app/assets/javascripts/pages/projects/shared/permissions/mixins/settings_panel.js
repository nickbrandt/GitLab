import { isEE } from '~/lib/utils/common_utils';

export default {
  computed: {
    isEE() {
      return isEE();
    },
  },
  data() {
    return {
      packagesAvailable: false,
    };
  },
};
