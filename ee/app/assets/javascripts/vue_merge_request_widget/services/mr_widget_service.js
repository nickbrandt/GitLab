import axios from '~/lib/utils/axios_utils';
import CEWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';

export default class MRWidgetService extends CEWidgetService {
  constructor(mr) {
    super(mr);

    this.apiApprovalsPath = mr.apiApprovalsPath;
    this.apiApprovalSettingsPath = mr.apiApprovalSettingsPath;
    this.apiApprovePath = mr.apiApprovePath;
    this.apiUnapprovePath = mr.apiUnapprovePath;
  }

  fetchApprovals() {
    return axios.get(this.apiApprovalsPath).then(res => res.data);
  }

  fetchApprovalSettings() {
    return axios.get(this.apiApprovalSettingsPath).then(res => res.data);
  }

  approveMergeRequest() {
    return axios.post(this.apiApprovePath).then(res => res.data);
  }
  approveMergeRequestWithAuth(approvalPassword) {
    return axios
      .post(this.apiApprovePath, { approval_password: approvalPassword })
      .then(res => res.data);
  }

  unapproveMergeRequest() {
    return axios.post(this.apiUnapprovePath).then(res => res.data);
  }

  // eslint-disable-next-line class-methods-use-this
  fetchReport(endpoint) {
    return axios.get(endpoint).then(res => res.data);
  }
}
