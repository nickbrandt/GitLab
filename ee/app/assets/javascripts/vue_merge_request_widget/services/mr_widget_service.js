import axios from '~/lib/utils/axios_utils';
import CEWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';

export default class MRWidgetService extends CEWidgetService {
  constructor(mr) {
    super(mr);

    this.approvalsPath = mr.approvalsPath;

    // This feature flag will be the default behavior when
    // https://gitlab.com/gitlab-org/gitlab-ee/issues/1979 is closed
    if (gon.features.approvalRules) {
      this.apiApprovalsPath = mr.apiApprovalsPath;
      this.apiApprovalSettingsPath = mr.apiApprovalSettingsPath;
      this.apiApprovePath = mr.apiApprovePath;
      this.apiUnapprovePath = mr.apiUnapprovePath;

      this.fetchApprovals = () => axios.get(this.apiApprovalsPath).then(res => res.data);
      this.fetchApprovalSettings = () =>
        axios.get(this.apiApprovalSettingsPath).then(res => res.data);
      this.approveMergeRequest = () => axios.post(this.apiApprovePath).then(res => res.data);
      this.unapproveMergeRequest = () => axios.post(this.apiUnapprovePath).then(res => res.data);
    }
  }

  fetchApprovals() {
    return axios.get(this.approvalsPath).then(res => res.data);
  }

  approveMergeRequest() {
    return axios.post(this.approvalsPath).then(res => res.data);
  }

  unapproveMergeRequest() {
    return axios.delete(this.approvalsPath).then(res => res.data);
  }

  // eslint-disable-next-line class-methods-use-this
  fetchReport(endpoint) {
    return axios.get(endpoint).then(res => res.data);
  }
}
