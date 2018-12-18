/**
 * This provides a stubbed API for approval rule requests.
 *
 * **PLEASE NOTE:**
 * - This class will be removed when the BE is merged for https://gitlab.com/gitlab-org/gitlab-ee/issues/1979
 */

export function createApprovalsServiceStub() {
  const projectApprovalRules = [];

  return {
    getProjectApprovalRules() {
      return Promise.resolve({
        data: { rules: projectApprovalRules },
      });
    },
  };
}

export default createApprovalsServiceStub();
