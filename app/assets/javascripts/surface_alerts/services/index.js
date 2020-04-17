import axios from '~/lib/utils/axios_utils';

export default {
  getSurfaceAlertsList({ endpoint }) {
    return axios.get(endpoint);
  },
};
