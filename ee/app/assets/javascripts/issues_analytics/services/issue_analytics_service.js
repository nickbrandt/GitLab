import axios from '~/lib/utils/axios_utils';

export default {
  fetchChartData(endpoint, filters) {
    return axios.get(`${endpoint}${filters}`);
  },
};
