import { DEFAULT_TIMEOUT, DEFAULT_ALLOWED_IP } from '../constants';

export default () => ({
  isLoading: false,
  timeout: DEFAULT_TIMEOUT,
  allowedIp: DEFAULT_ALLOWED_IP,
});
