import axios from '~/lib/utils/axios_utils';

class ServiceDeskService {
  constructor(endpoint) {
    this.endpoint = endpoint;
  }

  fetchIncomingEmail() {
    return axios.get(this.endpoint);
  }

  toggleServiceDesk(enable) {
    return axios.put(this.endpoint, { service_desk_enabled: enable });
  }
}

export default ServiceDeskService;
