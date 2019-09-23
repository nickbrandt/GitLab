import MockAdapter from 'axios-mock-adapter';
import * as actions from 'ee/vue_shared/license_management/store/actions';
import * as mutationTypes from 'ee/vue_shared/license_management/store/mutation_types';
import createState from 'ee/vue_shared/license_management/store/state';
import { LICENSE_APPROVAL_STATUS } from 'ee/vue_shared/license_management/constants';
import { TEST_HOST } from 'spec/test_constants';
import testAction from 'spec/helpers/vuex_action_helper';
import {
  approvedLicense,
  blacklistedLicense,
  licenseHeadIssues,
  licenseBaseIssues,
} from 'ee_spec/license_management/mock_data';
import axios from '~/lib/utils/axios_utils';

describe('License store actions', () => {
  const apiUrlManageLicenses = `${TEST_HOST}/licenses/management`;
  const headPath = `${TEST_HOST}/licenses/head`;
  const basePath = `${TEST_HOST}/licenses/base`;

  let axiosMock;
  let licenseId;
  let state;

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    state = {
      ...createState(),
      apiUrlManageLicenses,
      headPath,
      basePath,
      currentLicenseInModal: approvedLicense,
    };
    licenseId = approvedLicense.id;
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('setAPISettings', () => {
    it('commits SET_API_SETTINGS', done => {
      const payload = { headPath, apiUrlManageLicenses };
      testAction(
        actions.setAPISettings,
        payload,
        state,
        [{ type: mutationTypes.SET_API_SETTINGS, payload }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('setLicenseInModal', () => {
    it('commits SET_LICENSE_IN_MODAL with license', done => {
      testAction(
        actions.setLicenseInModal,
        approvedLicense,
        state,
        [{ type: mutationTypes.SET_LICENSE_IN_MODAL, payload: approvedLicense }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('resetLicenseInModal', () => {
    it('commits RESET_LICENSE_IN_MODAL', done => {
      testAction(
        actions.resetLicenseInModal,
        null,
        state,
        [{ type: mutationTypes.RESET_LICENSE_IN_MODAL }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('requestDeleteLicense', () => {
    it('commits REQUEST_DELETE_LICENSE', done => {
      testAction(
        actions.requestDeleteLicense,
        null,
        state,
        [{ type: mutationTypes.REQUEST_DELETE_LICENSE }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('receiveDeleteLicense', () => {
    it('commits RECEIVE_DELETE_LICENSE and dispatches loadManagedLicenses', done => {
      testAction(
        actions.receiveDeleteLicense,
        null,
        state,
        [{ type: mutationTypes.RECEIVE_DELETE_LICENSE }],
        [{ type: 'loadManagedLicenses' }],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('receiveDeleteLicenseError', () => {
    it('commits RECEIVE_DELETE_LICENSE_ERROR', done => {
      const error = new Error('Test');
      testAction(
        actions.receiveDeleteLicenseError,
        error,
        state,
        [{ type: mutationTypes.RECEIVE_DELETE_LICENSE_ERROR, payload: error }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('deleteLicense', () => {
    let endpointMock;
    let deleteUrl;

    beforeEach(() => {
      deleteUrl = `${apiUrlManageLicenses}/${licenseId}`;
      endpointMock = axiosMock.onDelete(deleteUrl);
    });

    it('dispatches requestDeleteLicense and receiveDeleteLicense for successful response', done => {
      endpointMock.replyOnce(req => {
        expect(req.url).toBe(deleteUrl);
        return [200, ''];
      });

      testAction(
        actions.deleteLicense,
        null,
        state,
        [],
        [{ type: 'requestDeleteLicense' }, { type: 'receiveDeleteLicense' }],
      )
        .then(done)
        .catch(done.fail);
    });

    it('dispatches requestDeleteLicense and receiveDeleteLicenseError for error response', done => {
      endpointMock.replyOnce(req => {
        expect(req.url).toBe(deleteUrl);
        return [500, ''];
      });

      testAction(
        actions.deleteLicense,
        null,
        state,
        [],
        [
          { type: 'requestDeleteLicense' },
          { type: 'receiveDeleteLicenseError', payload: jasmine.any(Error) },
        ],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('requestSetLicenseApproval', () => {
    it('commits REQUEST_SET_LICENSE_APPROVAL', done => {
      testAction(
        actions.requestSetLicenseApproval,
        null,
        state,
        [{ type: mutationTypes.REQUEST_SET_LICENSE_APPROVAL }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('receiveSetLicenseApproval', () => {
    gon.features = gon.features || {};
    const { parsedLicenseReport } = gon.features;

    afterEach(() => {
      gon.features.parsedLicenseReport = parsedLicenseReport;
    });

    describe('with the parsedLicenseReport feature flag enabled', () => {
      beforeEach(() => {
        gon.features.parsedLicenseReport = true;
      });

      it('commits RECEIVE_SET_LICENSE_APPROVAL and dispatches loadParsedLicenseReport', done => {
        testAction(
          actions.receiveSetLicenseApproval,
          null,
          state,
          [{ type: mutationTypes.RECEIVE_SET_LICENSE_APPROVAL }],
          [{ type: 'loadParsedLicenseReport' }],
        )
          .then(done)
          .catch(done.fail);
      });
    });

    describe('with the parsedLicenseReport feature flag disabled', () => {
      beforeEach(() => {
        gon.features.parsedLicenseReport = false;
      });

      it('commits RECEIVE_SET_LICENSE_APPROVAL and dispatches loadManagedLicenses', done => {
        testAction(
          actions.receiveSetLicenseApproval,
          null,
          state,
          [{ type: mutationTypes.RECEIVE_SET_LICENSE_APPROVAL }],
          [{ type: 'loadManagedLicenses' }],
        )
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('receiveSetLicenseApprovalError', () => {
    it('commits RECEIVE_SET_LICENSE_APPROVAL_ERROR', done => {
      const error = new Error('Test');
      testAction(
        actions.receiveSetLicenseApprovalError,
        error,
        state,
        [{ type: mutationTypes.RECEIVE_SET_LICENSE_APPROVAL_ERROR, payload: error }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('setLicenseApproval', () => {
    const newStatus = 'FAKE_STATUS';

    describe('uses POST endpoint for existing licenses;', function() {
      let putEndpointMock;
      let newLicense;

      beforeEach(() => {
        newLicense = { name: 'FOO LICENSE' };
        putEndpointMock = axiosMock.onPost(apiUrlManageLicenses);
      });

      it('dispatches requestSetLicenseApproval and receiveSetLicenseApproval for successful response', done => {
        putEndpointMock.replyOnce(req => {
          const { approval_status, name } = JSON.parse(req.data);

          expect(req.url).toBe(apiUrlManageLicenses);
          expect(approval_status).toBe(newStatus);
          expect(name).toBe(name);
          return [200, ''];
        });

        testAction(
          actions.setLicenseApproval,
          { license: newLicense, newStatus },
          state,
          [],
          [{ type: 'requestSetLicenseApproval' }, { type: 'receiveSetLicenseApproval' }],
        )
          .then(done)
          .catch(done.fail);
      });

      it('dispatches requestSetLicenseApproval and receiveSetLicenseApprovalError for error response', done => {
        putEndpointMock.replyOnce(req => {
          expect(req.url).toBe(apiUrlManageLicenses);
          return [500, ''];
        });

        testAction(
          actions.setLicenseApproval,
          { license: newLicense, newStatus },
          state,
          [],
          [
            { type: 'requestSetLicenseApproval' },
            { type: 'receiveSetLicenseApprovalError', payload: jasmine.any(Error) },
          ],
        )
          .then(done)
          .catch(done.fail);
      });
    });

    describe('uses PATCH endpoint for existing licenses;', function() {
      let patchEndpointMock;
      let licenseUrl;

      beforeEach(() => {
        licenseUrl = `${apiUrlManageLicenses}/${licenseId}`;
        patchEndpointMock = axiosMock.onPatch(licenseUrl);
      });

      it('dispatches requestSetLicenseApproval and receiveSetLicenseApproval for successful response', done => {
        patchEndpointMock.replyOnce(req => {
          expect(req.url).toBe(licenseUrl);
          const { approval_status, name } = JSON.parse(req.data);

          expect(approval_status).toBe(newStatus);
          expect(name).toBeUndefined();
          return [200, ''];
        });

        testAction(
          actions.setLicenseApproval,
          { license: approvedLicense, newStatus },
          state,
          [],
          [{ type: 'requestSetLicenseApproval' }, { type: 'receiveSetLicenseApproval' }],
        )
          .then(done)
          .catch(done.fail);
      });

      it('dispatches requestSetLicenseApproval and receiveSetLicenseApprovalError for error response', done => {
        patchEndpointMock.replyOnce(req => {
          expect(req.url).toBe(licenseUrl);
          return [500, ''];
        });

        testAction(
          actions.setLicenseApproval,
          { license: approvedLicense, newStatus },
          state,
          [],
          [
            { type: 'requestSetLicenseApproval' },
            { type: 'receiveSetLicenseApprovalError', payload: jasmine.any(Error) },
          ],
        )
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('approveLicense', () => {
    const newStatus = LICENSE_APPROVAL_STATUS.APPROVED;

    it('dispatches setLicenseApproval for un-approved licenses', done => {
      const license = { name: 'FOO' };

      testAction(
        actions.approveLicense,
        license,
        state,
        [],
        [{ type: 'setLicenseApproval', payload: { license, newStatus } }],
      )
        .then(done)
        .catch(done.fail);
    });

    it('dispatches setLicenseApproval for blacklisted licenses', done => {
      const license = blacklistedLicense;

      testAction(
        actions.approveLicense,
        license,
        state,
        [],
        [{ type: 'setLicenseApproval', payload: { license, newStatus } }],
      )
        .then(done)
        .catch(done.fail);
    });

    it('does not dispatch setLicenseApproval for approved licenses', done => {
      testAction(actions.approveLicense, approvedLicense, state, [], [])
        .then(done)
        .catch(done.fail);
    });
  });

  describe('blacklistLicense', () => {
    const newStatus = LICENSE_APPROVAL_STATUS.BLACKLISTED;

    it('dispatches setLicenseApproval for un-approved licenses', done => {
      const license = { name: 'FOO' };

      testAction(
        actions.blacklistLicense,
        license,
        state,
        [],
        [{ type: 'setLicenseApproval', payload: { license, newStatus } }],
      )
        .then(done)
        .catch(done.fail);
    });

    it('dispatches setLicenseApproval for approved licenses', done => {
      const license = approvedLicense;

      testAction(
        actions.blacklistLicense,
        license,
        state,
        [],
        [{ type: 'setLicenseApproval', payload: { license, newStatus } }],
      )
        .then(done)
        .catch(done.fail);
    });

    it('does not dispatch setLicenseApproval for blacklisted licenses', done => {
      testAction(actions.blacklistLicense, blacklistedLicense, state, [], [])
        .then(done)
        .catch(done.fail);
    });
  });

  describe('requestLoadManagedLicenses', () => {
    it('commits REQUEST_LOAD_MANAGED_LICENSES', done => {
      testAction(
        actions.requestLoadManagedLicenses,
        null,
        state,
        [{ type: mutationTypes.REQUEST_LOAD_MANAGED_LICENSES }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('receiveLoadManagedLicenses', () => {
    it('commits RECEIVE_LOAD_MANAGED_LICENSES', done => {
      const payload = [approvedLicense];
      testAction(
        actions.receiveLoadManagedLicenses,
        payload,
        state,
        [{ type: mutationTypes.RECEIVE_LOAD_MANAGED_LICENSES, payload }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('receiveLoadManagedLicensesError', () => {
    it('commits RECEIVE_LOAD_MANAGED_LICENSES_ERROR', done => {
      const error = new Error('Test');
      testAction(
        actions.receiveLoadManagedLicensesError,
        error,
        state,
        [{ type: mutationTypes.RECEIVE_LOAD_MANAGED_LICENSES_ERROR, payload: error }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('loadManagedLicenses', () => {
    let endpointMock;

    beforeEach(() => {
      endpointMock = axiosMock.onGet(apiUrlManageLicenses, { params: { per_page: 100 } });
    });

    it('dispatches requestLoadManagedLicenses and receiveLoadManagedLicenses for successful response', done => {
      const payload = [{ name: 'foo', approval_status: LICENSE_APPROVAL_STATUS.BLACKLISTED }];
      endpointMock.replyOnce(() => [200, payload]);

      testAction(
        actions.loadManagedLicenses,
        null,
        state,
        [],
        [{ type: 'requestLoadManagedLicenses' }, { type: 'receiveLoadManagedLicenses', payload }],
      )
        .then(done)
        .catch(done.fail);
    });

    it('dispatches requestLoadManagedLicenses and receiveLoadManagedLicensesError for error response', done => {
      endpointMock.replyOnce(() => [500, '']);

      testAction(
        actions.loadManagedLicenses,
        null,
        state,
        [],
        [
          { type: 'requestLoadManagedLicenses' },
          { type: 'receiveLoadManagedLicensesError', payload: jasmine.any(Error) },
        ],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('requestLoadLicenseReport', () => {
    it('commits REQUEST_LOAD_LICENSE_REPORT', done => {
      testAction(
        actions.requestLoadLicenseReport,
        null,
        state,
        [{ type: mutationTypes.REQUEST_LOAD_LICENSE_REPORT }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('receiveLoadLicenseReport', () => {
    it('commits RECEIVE_LOAD_LICENSE_REPORT', done => {
      const payload = { headReport: licenseHeadIssues, baseReport: licenseBaseIssues };
      testAction(
        actions.receiveLoadLicenseReport,
        payload,
        state,
        [{ type: mutationTypes.RECEIVE_LOAD_LICENSE_REPORT, payload }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('receiveLoadLicenseReportError', () => {
    it('commits RECEIVE_LOAD_LICENSE_REPORT_ERROR', done => {
      const error = new Error('Test');
      testAction(
        actions.receiveLoadLicenseReportError,
        error,
        state,
        [{ type: mutationTypes.RECEIVE_LOAD_LICENSE_REPORT_ERROR, payload: error }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('loadLicenseReport', () => {
    let headMock;
    let baseMock;

    beforeEach(() => {
      headMock = axiosMock.onGet(headPath);
      baseMock = axiosMock.onGet(basePath);
    });

    it('dispatches requestLoadLicenseReport and receiveLoadLicenseReport for successful response', done => {
      headMock.replyOnce(() => [200, licenseHeadIssues]);
      baseMock.replyOnce(() => [200, licenseBaseIssues]);

      const payload = { headReport: licenseHeadIssues, baseReport: licenseBaseIssues };
      testAction(
        actions.loadLicenseReport,
        null,
        state,
        [],
        [{ type: 'requestLoadLicenseReport' }, { type: 'receiveLoadLicenseReport', payload }],
      )
        .then(done)
        .catch(done.fail);
    });

    it('dispatches requestLoadLicenseReport and receiveLoadLicenseReport for 404 on basePath', done => {
      headMock.replyOnce(() => [200, licenseHeadIssues]);
      baseMock.replyOnce(() => [404, null]);

      const payload = { headReport: licenseHeadIssues, baseReport: {} };
      testAction(
        actions.loadLicenseReport,
        null,
        state,
        [],
        [{ type: 'requestLoadLicenseReport' }, { type: 'receiveLoadLicenseReport', payload }],
      )
        .then(done)
        .catch(done.fail);
    });

    it('dispatches requestLoadLicenseReport and receiveLoadLicenseReportError for error response on head Path', done => {
      headMock.replyOnce(() => [500, '']);
      baseMock.replyOnce(() => [200, licenseBaseIssues]);

      testAction(
        actions.loadLicenseReport,
        null,
        state,
        [],
        [
          { type: 'requestLoadLicenseReport' },
          { type: 'receiveLoadLicenseReportError', payload: jasmine.any(Error) },
        ],
      )
        .then(done)
        .catch(done.fail);
    });

    it('dispatches requestLoadLicenseReport and receiveLoadLicenseReportError for error response on base Path', done => {
      headMock.replyOnce(() => [200, licenseHeadIssues]);
      baseMock.replyOnce(() => [500, '']);

      testAction(
        actions.loadLicenseReport,
        null,
        state,
        [],
        [
          { type: 'requestLoadLicenseReport' },
          { type: 'receiveLoadLicenseReportError', payload: jasmine.any(Error) },
        ],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('requestLoadParsedLicenseReport', () => {
    it(`should commit ${mutationTypes.REQUEST_LOAD_PARSED_LICENSE_REPORT}`, done => {
      testAction(
        actions.requestLoadParsedLicenseReport,
        null,
        state,
        [{ type: mutationTypes.REQUEST_LOAD_PARSED_LICENSE_REPORT }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('receiveLoadParsedLicenseReport', () => {
    it(`should commit ${mutationTypes.RECEIVE_LOAD_PARSED_LICENSE_REPORT} with the correct payload`, done => {
      const payload = { newLicenses: [{ name: 'foo' }] };

      testAction(
        actions.receiveLoadParsedLicenseReport,
        payload,
        state,
        [{ type: mutationTypes.RECEIVE_LOAD_PARSED_LICENSE_REPORT, payload }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('receiveLoadParsedLicenseReportError', () => {
    it(`should commit ${mutationTypes.RECEIVE_LOAD_PARSED_LICENSE_REPORT_ERROR}`, done => {
      const payload = new Error('Test');

      testAction(
        actions.receiveLoadParsedLicenseReportError,
        payload,
        state,
        [{ type: mutationTypes.RECEIVE_LOAD_PARSED_LICENSE_REPORT_ERROR, payload }],
        [],
      )
        .then(done)
        .catch(done.fail);
    });
  });

  describe('loadParsedLicenseReport', () => {
    const licensesApiPath = `${TEST_HOST}/licensesApiPath`;
    let licensesApiMock;
    let rawLicenseReport;

    beforeEach(() => {
      licensesApiMock = axiosMock.onGet(licensesApiPath);
      state = {
        ...createState(),
        licensesApiPath,
      };
    });

    describe('pipeline reports', () => {
      beforeEach(() => {
        rawLicenseReport = [
          {
            name: 'MIT',
            classification: { id: 2, approval_status: 'blacklisted', name: 'MIT' },
            dependencies: [{ name: 'vue' }],
            count: 1,
            url: 'http://opensource.org/licenses/mit-license',
          },
        ];
      });

      it('should fetch, parse, and dispatch the new licenses on a successful request', done => {
        licensesApiMock.replyOnce(() => [200, rawLicenseReport]);

        const parsedLicenses = {
          existingLicenses: [],
          newLicenses: [
            {
              ...rawLicenseReport[0],
              id: 2,
              approvalStatus: 'blacklisted',
              packages: [{ name: 'vue' }],
              status: 'failed',
            },
          ],
        };

        testAction(
          actions.loadParsedLicenseReport,
          null,
          state,
          [],
          [
            { type: 'requestLoadParsedLicenseReport' },
            { type: 'receiveLoadParsedLicenseReport', payload: parsedLicenses },
          ],
        )
          .then(done)
          .catch(done.fail);
      });

      it('should send an error on an unsuccesful request', done => {
        licensesApiMock.replyOnce(400);

        testAction(
          actions.loadParsedLicenseReport,
          null,
          state,
          [],
          [{ type: 'requestLoadParsedLicenseReport' }, { type: 'receiveLoadLicenseReportError' }],
        )
          .then(done)
          .catch(done.fail);
      });
    });

    describe('MR widget reports', () => {
      beforeEach(() => {
        rawLicenseReport = {
          new_licenses: [
            {
              name: 'Apache 2.0',
              classification: { id: 1, approval_status: 'approved', name: 'Apache 2.0' },
              dependencies: [{ name: 'echarts' }],
              count: 1,
              url: 'http://www.apache.org/licenses/LICENSE-2.0.txt',
            },
            {
              name: 'New BSD',
              classification: { id: 3, approval_status: 'unclassified', name: 'New BSD' },
              dependencies: [{ name: 'zrender' }],
              count: 1,
              url: 'http://opensource.org/licenses/BSD-3-Clause',
            },
          ],
          existing_licenses: [
            {
              name: 'MIT',
              classification: { id: 2, approval_status: 'blacklisted', name: 'MIT' },
              dependencies: [{ name: 'vue' }],
              count: 1,
              url: 'http://opensource.org/licenses/mit-license',
            },
          ],
          removed_licenses: [],
        };
      });

      it('should fetch, parse, and dispatch the new licenses on a successful request', done => {
        licensesApiMock.replyOnce(() => [200, rawLicenseReport]);

        const parsedLicenses = {
          existingLicenses: [
            {
              ...rawLicenseReport.existing_licenses[0],
              id: 2,
              approvalStatus: 'blacklisted',
              packages: [{ name: 'vue' }],
              status: 'failed',
            },
          ],
          newLicenses: [
            {
              ...rawLicenseReport.new_licenses[0],
              id: 1,
              approvalStatus: 'approved',
              packages: [{ name: 'echarts' }],
              status: 'success',
            },
            {
              ...rawLicenseReport.new_licenses[1],
              id: 3,
              approvalStatus: 'unclassified',
              packages: [{ name: 'zrender' }],
              status: 'neutral',
            },
          ],
        };

        testAction(
          actions.loadParsedLicenseReport,
          null,
          state,
          [],
          [
            { type: 'requestLoadParsedLicenseReport' },
            { type: 'receiveLoadParsedLicenseReport', payload: parsedLicenses },
          ],
        )
          .then(done)
          .catch(done.fail);
      });
    });
  });
});
