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

  updateTemplate(template, isEnabled) {
    const body = {
      issue_template_key: template,
      service_desk_enabled: isEnabled,
    };
    return axios.put(this.endpoint, body);
  }
}

export default ServiceDeskService;
