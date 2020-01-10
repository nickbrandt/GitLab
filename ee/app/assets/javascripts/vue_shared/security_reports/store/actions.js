import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';
import pollUntilComplete from '~/lib/utils/poll_until_complete';
import { s__, sprintf } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import toast from '~/vue_shared/plugins/global_toast';
import * as types from './mutation_types';
import downloadPatchHelper from './utils/download_patch_helper';

/**
 * A lot of this file has duplicate actions to
 * ee/app/assets/javascripts/security_dashboard/store/modules/vulnerabilities/actions.js
 * This is being addressed in the following issues:
 *
 * https://gitlab.com/gitlab-org/gitlab/issues/8146
 * https://gitlab.com/gitlab-org/gitlab/issues/8519
 */

const hideModal = () => $('#modal-mrwidget-security-issue').modal('hide');

export const setHeadBlobPath = ({ commit }, blobPath) => commit(types.SET_HEAD_BLOB_PATH, blobPath);

export const setBaseBlobPath = ({ commit }, blobPath) => commit(types.SET_BASE_BLOB_PATH, blobPath);

export const setSourceBranch = ({ commit }, branch) => commit(types.SET_SOURCE_BRANCH, branch);

export const setVulnerabilityFeedbackPath = ({ commit }, path) =>
  commit(types.SET_VULNERABILITY_FEEDBACK_PATH, path);

export const setVulnerabilityFeedbackHelpPath = ({ commit }, path) =>
  commit(types.SET_VULNERABILITY_FEEDBACK_HELP_PATH, path);

export const setCreateVulnerabilityFeedbackIssuePath = ({ commit }, path) =>
  commit(types.SET_CREATE_VULNERABILITY_FEEDBACK_ISSUE_PATH, path);

export const setCreateVulnerabilityFeedbackMergeRequestPath = ({ commit }, path) =>
  commit(types.SET_CREATE_VULNERABILITY_FEEDBACK_MERGE_REQUEST_PATH, path);

export const setCreateVulnerabilityFeedbackDismissalPath = ({ commit }, path) =>
  commit(types.SET_CREATE_VULNERABILITY_FEEDBACK_DISMISSAL_PATH, path);

export const setPipelineId = ({ commit }, id) => commit(types.SET_PIPELINE_ID, id);

export const setCanCreateIssuePermission = ({ commit }, permission) =>
  commit(types.SET_CAN_CREATE_ISSUE_PERMISSION, permission);

export const setCanCreateFeedbackPermission = ({ commit }, permission) =>
  commit(types.SET_CAN_CREATE_FEEDBACK_PERMISSION, permission);

/**
 * SAST CONTAINER
 */
export const setSastContainerHeadPath = ({ commit }, path) =>
  commit(types.SET_SAST_CONTAINER_HEAD_PATH, path);

export const setSastContainerBasePath = ({ commit }, path) =>
  commit(types.SET_SAST_CONTAINER_BASE_PATH, path);

export const setSastContainerDiffEndpoint = ({ commit }, path) =>
  commit(types.SET_SAST_CONTAINER_DIFF_ENDPOINT, path);

export const requestSastContainerReports = ({ commit }) =>
  commit(types.REQUEST_SAST_CONTAINER_REPORTS);

export const receiveSastContainerReports = ({ commit }, response) =>
  commit(types.RECEIVE_SAST_CONTAINER_REPORTS, response);

export const receiveSastContainerError = ({ commit }, error) =>
  commit(types.RECEIVE_SAST_CONTAINER_ERROR, error);

export const receiveSastContainerDiffSuccess = ({ commit }, response) =>
  commit(types.RECEIVE_SAST_CONTAINER_DIFF_SUCCESS, response);

export const receiveSastContainerDiffError = ({ commit }) =>
  commit(types.RECEIVE_SAST_CONTAINER_DIFF_ERROR);

export const fetchSastContainerDiff = ({ state, dispatch }) => {
  dispatch('requestSastContainerReports');

  return Promise.all([
    pollUntilComplete(state.sastContainer.paths.diffEndpoint),
    axios.get(state.vulnerabilityFeedbackPath, {
      params: {
        category: 'container_scanning',
      },
    }),
  ])
    .then(values => {
      dispatch('receiveSastContainerDiffSuccess', {
        diff: values[0].data,
        enrichData: values[1].data,
      });
    })
    .catch(() => {
      dispatch('receiveSastContainerDiffError');
    });
};

export const fetchSastContainerReports = ({ state, dispatch }) => {
  const { base, head } = state.sastContainer.paths;

  dispatch('requestSastContainerReports');

  return Promise.all([
    head ? axios.get(head) : Promise.resolve(),
    base ? axios.get(base) : Promise.resolve(),
    axios.get(state.vulnerabilityFeedbackPath, {
      params: {
        category: 'container_scanning',
      },
    }),
  ])
    .then(values => {
      dispatch('receiveSastContainerReports', {
        head: values[0] ? values[0].data : null,
        base: values[1] ? values[1].data : null,
        enrichData: values && values[2] ? values[2].data : [],
      });
    })
    .catch(() => {
      dispatch('receiveSastContainerError');
    });
};

export const updateContainerScanningIssue = ({ commit }, issue) =>
  commit(types.UPDATE_CONTAINER_SCANNING_ISSUE, issue);

/**
 * DAST
 */
export const setDastHeadPath = ({ commit }, path) => commit(types.SET_DAST_HEAD_PATH, path);

export const setDastBasePath = ({ commit }, path) => commit(types.SET_DAST_BASE_PATH, path);

export const setDastDiffEndpoint = ({ commit }, path) => commit(types.SET_DAST_DIFF_ENDPOINT, path);

export const requestDastReports = ({ commit }) => commit(types.REQUEST_DAST_REPORTS);

export const receiveDastReports = ({ commit }, response) =>
  commit(types.RECEIVE_DAST_REPORTS, response);

export const receiveDastError = ({ commit }, error) => commit(types.RECEIVE_DAST_ERROR, error);

export const fetchDastReports = ({ state, dispatch }) => {
  const { base, head } = state.dast.paths;

  dispatch('requestDastReports');

  return Promise.all([
    head ? axios.get(head) : Promise.resolve(),
    base ? axios.get(base) : Promise.resolve(),
    axios.get(state.vulnerabilityFeedbackPath, {
      params: {
        category: 'dast',
      },
    }),
  ])
    .then(values => {
      dispatch('receiveDastReports', {
        head: values && values[0] ? values[0].data : null,
        base: values && values[1] ? values[1].data : null,
        enrichData: values && values[2] ? values[2].data : [],
      });
    })
    .catch(() => {
      dispatch('receiveDastError');
    });
};

export const updateDastIssue = ({ commit }, issue) => commit(types.UPDATE_DAST_ISSUE, issue);

export const receiveDastDiffSuccess = ({ commit }, response) =>
  commit(types.RECEIVE_DAST_DIFF_SUCCESS, response);

export const receiveDastDiffError = ({ commit }) => commit(types.RECEIVE_DAST_DIFF_ERROR);

export const fetchDastDiff = ({ state, dispatch }) => {
  dispatch('requestDastReports');

  return Promise.all([
    pollUntilComplete(state.dast.paths.diffEndpoint),
    axios.get(state.vulnerabilityFeedbackPath, {
      params: {
        category: 'dast',
      },
    }),
  ])
    .then(values => {
      dispatch('receiveDastDiffSuccess', {
        diff: values[0].data,
        enrichData: values[1].data,
      });
    })
    .catch(() => {
      dispatch('receiveDastDiffError');
    });
};

/**
 * DEPENDENCY SCANNING
 */
export const setDependencyScanningHeadPath = ({ commit }, path) =>
  commit(types.SET_DEPENDENCY_SCANNING_HEAD_PATH, path);

export const setDependencyScanningBasePath = ({ commit }, path) =>
  commit(types.SET_DEPENDENCY_SCANNING_BASE_PATH, path);

export const setDependencyScanningDiffEndpoint = ({ commit }, path) =>
  commit(types.SET_DEPENDENCY_SCANNING_DIFF_ENDPOINT, path);

export const requestDependencyScanningReports = ({ commit }) =>
  commit(types.REQUEST_DEPENDENCY_SCANNING_REPORTS);

export const receiveDependencyScanningReports = ({ commit }, response) =>
  commit(types.RECEIVE_DEPENDENCY_SCANNING_REPORTS, response);

export const receiveDependencyScanningError = ({ commit }, error) =>
  commit(types.RECEIVE_DEPENDENCY_SCANNING_ERROR, error);

export const receiveDependencyScanningDiffSuccess = ({ commit }, response) =>
  commit(types.RECEIVE_DEPENDENCY_SCANNING_DIFF_SUCCESS, response);

export const receiveDependencyScanningDiffError = ({ commit }) =>
  commit(types.RECEIVE_DEPENDENCY_SCANNING_DIFF_ERROR);

export const fetchDependencyScanningDiff = ({ state, dispatch }) => {
  dispatch('requestDependencyScanningReports');

  return Promise.all([
    pollUntilComplete(state.dependencyScanning.paths.diffEndpoint),
    axios.get(state.vulnerabilityFeedbackPath, {
      params: {
        category: 'dependency_scanning',
      },
    }),
  ])
    .then(values => {
      dispatch('receiveDependencyScanningDiffSuccess', {
        diff: values[0].data,
        enrichData: values[1].data,
      });
    })
    .catch(() => {
      dispatch('receiveDependencyScanningDiffError');
    });
};

export const fetchDependencyScanningReports = ({ state, dispatch }) => {
  const { base, head } = state.dependencyScanning.paths;

  dispatch('requestDependencyScanningReports');

  return Promise.all([
    head ? axios.get(head) : Promise.resolve(),
    base ? axios.get(base) : Promise.resolve(),
    axios.get(state.vulnerabilityFeedbackPath, {
      params: {
        category: 'dependency_scanning',
      },
    }),
  ])
    .then(values => {
      dispatch('receiveDependencyScanningReports', {
        head: values[0] ? values[0].data : null,
        base: values[1] ? values[1].data : null,
        enrichData: values && values[2] ? values[2].data : [],
      });
    })
    .catch(() => {
      dispatch('receiveDependencyScanningError');
    });
};

export const updateDependencyScanningIssue = ({ commit }, issue) =>
  commit(types.UPDATE_DEPENDENCY_SCANNING_ISSUE, issue);

export const openModal = ({ dispatch }, payload) => {
  dispatch('setModalData', payload);

  $('#modal-mrwidget-security-issue').modal('show');
};

export const setModalData = ({ commit }, payload) => commit(types.SET_ISSUE_MODAL_DATA, payload);
export const requestDismissVulnerability = ({ commit }) =>
  commit(types.REQUEST_DISMISS_VULNERABILITY);
export const receiveDismissVulnerability = ({ commit }, payload) =>
  commit(types.RECEIVE_DISMISS_VULNERABILITY_SUCCESS, payload);
export const receiveDismissVulnerabilityError = ({ commit }, error) =>
  commit(types.RECEIVE_DISMISS_VULNERABILITY_ERROR, error);

export const dismissVulnerability = ({ state, dispatch }, comment) => {
  dispatch('requestDismissVulnerability');

  const toastMsg = sprintf(s__("Security Reports|Dismissed '%{vulnerabilityName}'"), {
    vulnerabilityName: state.modal.vulnerability.name,
  });

  axios
    .post(state.createVulnerabilityFeedbackDismissalPath, {
      vulnerability_feedback: {
        category: state.modal.vulnerability.category,
        comment,
        feedback_type: 'dismissal',
        pipeline_id: state.pipelineId,
        project_fingerprint: state.modal.vulnerability.project_fingerprint,
        vulnerability_data: state.modal.vulnerability,
      },
    })
    .then(({ data }) => {
      const updatedIssue = {
        ...state.modal.vulnerability,
        isDismissed: true,
        dismissalFeedback: data,
      };

      dispatch('closeDismissalCommentBox');
      dispatch('receiveDismissVulnerability', updatedIssue);
      hideModal();
      toast(toastMsg);
    })
    .catch(() => {
      dispatch(
        'receiveDismissVulnerabilityError',
        s__('ciReport|There was an error dismissing the vulnerability. Please try again.'),
      );
    });
};

export const addDismissalComment = ({ state, dispatch }, { comment }) => {
  dispatch('requestAddDismissalComment');

  const { vulnerability } = state.modal;
  const { dismissalFeedback } = vulnerability;
  const url = `${state.createVulnerabilityFeedbackDismissalPath}/${dismissalFeedback.id}`;

  const editingDismissalContent =
    dismissalFeedback.comment_details && dismissalFeedback.comment_details.comment;

  const toastMsg = editingDismissalContent
    ? sprintf(s__("Security Reports|Comment edited on '%{vulnerabilityName}'"), {
        vulnerabilityName: vulnerability.name,
      })
    : sprintf(s__("Security Reports|Comment added to '%{vulnerabilityName}'"), {
        vulnerabilityName: vulnerability.name,
      });

  axios
    .patch(url, {
      project_id: dismissalFeedback.project_id,
      id: dismissalFeedback.id,
      comment,
    })
    .then(({ data }) => {
      dispatch('closeDismissalCommentBox');
      dispatch('receiveAddDismissalCommentSuccess', { data });
      toast(toastMsg);
    })
    .catch(() => {
      dispatch(
        'receiveAddDismissalCommentError',
        s__('Security Reports|There was an error adding the comment.'),
      );
    });
};

export const deleteDismissalComment = ({ state, dispatch }) => {
  dispatch('requestDeleteDismissalComment');

  const { vulnerability } = state.modal;
  const { dismissalFeedback } = vulnerability;
  const url = `${state.createVulnerabilityFeedbackDismissalPath}/${dismissalFeedback.id}`;
  const toastMsg = sprintf(s__("Security Reports|Comment deleted on '%{vulnerabilityName}'"), {
    vulnerabilityName: vulnerability.name,
  });

  axios
    .patch(url, {
      project_id: dismissalFeedback.project_id,
      comment: '',
    })
    .then(({ data }) => {
      dispatch('closeDismissalCommentBox');
      dispatch('receiveDeleteDismissalCommentSuccess', { data });
      toast(toastMsg);
    })
    .catch(() => {
      dispatch(
        'receiveDeleteDismissalCommentError',
        s__('Security Reports|There was an error deleting the comment.'),
      );
    });
};

export const requestDeleteDismissalComment = ({ commit }) => {
  commit(types.REQUEST_DELETE_DISMISSAL_COMMENT);
};

export const receiveDeleteDismissalCommentSuccess = ({ commit }, payload) => {
  commit(types.RECEIVE_DELETE_DISMISSAL_COMMENT_SUCCESS, payload);
  hideModal();
};

export const receiveDeleteDismissalCommentError = ({ commit }, error) => {
  commit(types.RECEIVE_DELETE_DISMISSAL_COMMENT_ERROR, error);
};

export const requestAddDismissalComment = ({ commit }) => {
  commit(types.REQUEST_ADD_DISMISSAL_COMMENT);
};

export const receiveAddDismissalCommentSuccess = ({ commit }, payload) => {
  commit(types.RECEIVE_ADD_DISMISSAL_COMMENT_SUCCESS, payload);
  hideModal();
};

export const receiveAddDismissalCommentError = ({ commit }, error) => {
  commit(types.RECEIVE_ADD_DISMISSAL_COMMENT_ERROR, error);
};

export const revertDismissVulnerability = ({ state, dispatch }) => {
  dispatch('requestDismissVulnerability');

  axios
    .delete(
      state.modal.vulnerability.dismissalFeedback.destroy_vulnerability_feedback_dismissal_path,
    )
    .then(() => {
      const updatedIssue = {
        ...state.modal.vulnerability,
        isDismissed: false,
        dismissalFeedback: null,
      };

      dispatch('receiveDismissVulnerability', updatedIssue);

      hideModal();
    })
    .catch(() =>
      dispatch(
        'receiveDismissVulnerabilityError',
        s__('ciReport|There was an error reverting the dismissal. Please try again.'),
      ),
    );
};

export const showDismissalDeleteButtons = ({ commit }) => {
  commit(types.SHOW_DISMISSAL_DELETE_BUTTONS);
};

export const hideDismissalDeleteButtons = ({ commit }) => {
  commit(types.HIDE_DISMISSAL_DELETE_BUTTONS);
};

export const requestCreateIssue = ({ commit }) => commit(types.REQUEST_CREATE_ISSUE);
export const receiveCreateIssue = ({ commit }) => commit(types.RECEIVE_CREATE_ISSUE_SUCCESS);
export const receiveCreateIssueError = ({ commit }, error) =>
  commit(types.RECEIVE_CREATE_ISSUE_ERROR, error);

export const createNewIssue = ({ state, dispatch }) => {
  dispatch('requestCreateIssue');

  axios
    .post(state.createVulnerabilityFeedbackIssuePath, {
      vulnerability_feedback: {
        feedback_type: 'issue',
        category: state.modal.vulnerability.category,
        project_fingerprint: state.modal.vulnerability.project_fingerprint,
        pipeline_id: state.pipelineId,
        vulnerability_data: state.modal.vulnerability,
      },
    })
    .then(response => {
      dispatch('receiveCreateIssue');
      // redirect the user to the created issue
      visitUrl(response.data.issue_url);
    })
    .catch(() =>
      dispatch(
        'receiveCreateIssueError',
        s__('ciReport|There was an error creating the issue. Please try again.'),
      ),
    );
};

export const createMergeRequest = ({ state, dispatch }) => {
  const { vulnerability } = state.modal;
  const { category, project_fingerprint } = vulnerability;

  vulnerability.target_branch = state.sourceBranch;

  dispatch('requestCreateMergeRequest');

  axios
    .post(state.createVulnerabilityFeedbackMergeRequestPath, {
      vulnerability_feedback: {
        feedback_type: 'merge_request',
        category,
        project_fingerprint,
        vulnerability_data: vulnerability,
      },
    })
    .then(({ data }) => {
      dispatch('receiveCreateMergeRequestSuccess', data);
    })
    .catch(() => {
      dispatch(
        'receiveCreateMergeRequestError',
        s__('ciReport|There was an error creating the merge request. Please try again.'),
      );
    });
};

export const downloadPatch = ({ state }) => {
  /* 
    This action doesn't actually mutate the Vuex state and is a dirty
    workaround to modifying the dom. We do this because gl-split-button 
    relies on a old version of vue-bootstrap and it doesn't allow us to 
    set a href for a file download. 

    https://gitlab.com/gitlab-org/gitlab-ui/issues/188#note_165808493
  */
  const { vulnerability } = state.modal;
  downloadPatchHelper(vulnerability.remediations[0].diff);
  $('#modal-mrwidget-security-issue').modal('hide');
};

export const requestCreateMergeRequest = ({ commit }) => {
  commit(types.REQUEST_CREATE_MERGE_REQUEST);
};

export const receiveCreateMergeRequestSuccess = ({ commit }, payload) => {
  commit(types.RECEIVE_CREATE_MERGE_REQUEST_SUCCESS, payload);
};

export const receiveCreateMergeRequestError = ({ commit }) => {
  commit(types.RECEIVE_CREATE_MERGE_REQUEST_ERROR);
};

export const openDismissalCommentBox = ({ commit }) => {
  commit(types.OPEN_DISMISSAL_COMMENT_BOX);
};

export const closeDismissalCommentBox = ({ commit }) => {
  commit(types.CLOSE_DISMISSAL_COMMENT_BOX);
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
