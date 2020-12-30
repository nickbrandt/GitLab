import axios from 'axios';

const getJwt = async () => {
  return AP.context.getToken();
};

export const removeSubscription = async (subscriptionObject) => {
  const jwt = await getJwt();

  return axios.delete(subscriptionObject.path, {
    data: {
      jwt,
    },
  });
};

export const addSubscription = async (actionUrl, namespace) => {
  const jwt = await getJwt();

  return axios.post(actionUrl, {
    jwt,
    namespace_path: namespace,
  });
};

export const fetchSubscriptions = async (url) => {
  const jwt = await getJwt();

  return axios.get(url, {
    headers: {
      Accept: 'application/json',
    },
    params: {
      jwt,
    },
  });
};
