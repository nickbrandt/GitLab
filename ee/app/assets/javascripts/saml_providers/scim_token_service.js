import axios from '~/lib/utils/axios_utils';

export default class SCIMTokenService {
  constructor(groupPath) {
    this.axios = axios.create({
      baseURL: groupPath,
    });
  }

  generateNewSCIMToken() {
    return this.axios.post('/-/scim_oauth');
  }
}
