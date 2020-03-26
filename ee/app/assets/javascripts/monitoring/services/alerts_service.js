import axios from '~/lib/utils/axios_utils';

export const createAlert = (alertPath, { prometheus_metric_id, operator, threshold }) => {
  return axios
    .post(alertPath, { prometheus_metric_id, operator, threshold })
    .then(resp => resp.data);
};

export const readAlert = alertPath => axios.get(alertPath).then(resp => resp.data);

export const updateAlert = (alertPath, { operator, threshold }) =>
  axios.put(alertPath, { operator, threshold }).then(resp => resp.data);

export const deleteAlert = alertPath => axios.delete(alertPath).then(resp => resp.data);
