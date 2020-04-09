import createState from 'ee/vue_shared/license_compliance/store/state';
import * as getters from 'ee/vue_shared/license_compliance/store/getters';

import { licenseReport as licenseReportMock } from '../mock_data';

describe('getters', () => {
  let state;

  describe('isLoading', () => {
    it('is true if `isLoadingManagedLicenses` is true OR `isLoadingLicenseReport` is true', () => {
      state = createState();
      state.isLoadingManagedLicenses = true;
      state.isLoadingLicenseReport = true;

      expect(getters.isLoading(state)).toBe(true);
      state.isLoadingManagedLicenses = false;
      state.isLoadingLicenseReport = true;

      expect(getters.isLoading(state)).toBe(true);
      state.isLoadingManagedLicenses = true;
      state.isLoadingLicenseReport = false;

      expect(getters.isLoading(state)).toBe(true);
      state.isLoadingManagedLicenses = false;
      state.isLoadingLicenseReport = false;

      expect(getters.isLoading(state)).toBe(false);
    });
  });

  describe('isLicenseBeingUpdated', () => {
    beforeEach(() => {
      state = createState();
    });

    it.each([5, null])('returns true if given license is being updated', licenseId => {
      state.pendingLicenses = [licenseId];

      expect(getters.isLicenseBeingUpdated(state)(licenseId)).toBe(true);
    });

    it('returns true if a new license is being added and no param is passed to the getter', () => {
      state.pendingLicenses = [null];

      expect(getters.isLicenseBeingUpdated(state)()).toBe(true);
    });

    it.each`
      pendingLicenses | queriedLicense
      ${[null]}       | ${5}
      ${[5]}          | ${null}
      ${[5]}          | ${undefined}
    `(
      'returns false if given license is not being updated',
      ({ pendingLicenses, queriedLicense }) => {
        state.pendingLicenses = pendingLicenses;
        expect(getters.isLicenseBeingUpdated(state)(queriedLicense)).toBe(false);
      },
    );
  });

  describe('isAddingNewLicense', () => {
    it.each([true, false])('calls isLicenseBeingUpdated internally', returnValue => {
      const isLicenseBeingUpdatedMock = jest.fn().mockImplementation(() => returnValue);
      expect(
        getters.isAddingNewLicense({}, { isLicenseBeingUpdated: isLicenseBeingUpdatedMock }),
      ).toBe(returnValue);
    });
  });

  describe('hasPendingLicenses', () => {
    it('returns true if there are some pending licenses', () => {
      state = createState();
      state.pendingLicenses = [null];
      expect(getters.hasPendingLicenses(state)).toBe(true);
    });

    it('returns false if there are no pending licenses', () => {
      state = createState();
      state.pendingLicenses = [];
      expect(getters.hasPendingLicenses(state)).toBe(false);
    });
  });

  describe('licenseReport', () => {
    it('should return the new licenses from the state', () => {
      const newLicenses = { test: 'foo' };
      state = { ...createState(), newLicenses };

      expect(getters.licenseReport(state)).toBe(newLicenses);
    });
  });

  describe('licenseReportGroups', () => {
    it('returns an array of objects containing information about the group and licenses', () => {
      const licensesSuccess = [
        { status: 'success', value: 'foo' },
        { status: 'success', value: 'bar' },
      ];
      const licensesNeutral = [
        { status: 'neutral', value: 'foo' },
        { status: 'neutral', value: 'bar' },
      ];
      const licensesFailed = [
        { status: 'failed', value: 'foo' },
        { status: 'failed', value: 'bar' },
      ];
      const newLicenses = [...licensesSuccess, ...licensesNeutral, ...licensesFailed];

      expect(getters.licenseReportGroups({ newLicenses })).toEqual([
        {
          name: 'Denied',
          description: `Out-of-compliance with this project's policies and should be removed`,
          status: 'failed',
          licenses: licensesFailed,
        },
        {
          name: 'Uncategorized',
          description: 'No policy matches this license',
          status: 'neutral',
          licenses: licensesNeutral,
        },
        {
          name: 'Allowed',
          description: 'Acceptable for use in this project',
          status: 'success',
          licenses: licensesSuccess,
        },
      ]);
    });

    it.each(['failed', 'neutral', 'success'])(
      `it filters report-groups that don't have the given status: %s`,
      status => {
        const newLicenses = [{ status }];

        expect(getters.licenseReportGroups({ newLicenses })).toEqual([
          expect.objectContaining({
            status,
            licenses: newLicenses,
          }),
        ]);
      },
    );
  });

  describe('licenseSummaryText', () => {
    describe('when licenses exist on both the HEAD and the BASE', () => {
      beforeEach(() => {
        state = {
          ...createState(),
          loadLicenseReportError: null,
          newLicenses: ['foo'],
          existingLicenses: ['bar'],
        };
      });

      it('should be `Loading License Compliance report` text if isLoading', () => {
        const mockGetters = {};
        mockGetters.isLoading = true;

        expect(getters.licenseSummaryText(state, mockGetters)).toBe(
          'Loading License Compliance report',
        );
      });

      it('should be `Failed to load License Compliance report` text if an error has happened', () => {
        const mockGetters = {};
        state.loadLicenseReportError = new Error('Test');

        expect(getters.licenseSummaryText(state, mockGetters)).toBe(
          'Failed to load License Compliance report',
        );
      });

      it.each`
        givenLicenseReport                              | givenReportContainsBlacklistedLicense | expectedSummaryText
        ${[]}                                           | ${false}                              | ${'License Compliance detected no new licenses'}
        ${[licenseReportMock[0]]}                       | ${false}                              | ${'License Compliance detected 1 new license'}
        ${[licenseReportMock[0], licenseReportMock[0]]} | ${false}                              | ${'License Compliance detected 2 new licenses'}
        ${[licenseReportMock[0]]}                       | ${true}                               | ${'License Compliance detected 1 new license and policy violation; approval required'}
        ${[licenseReportMock[0], licenseReportMock[0]]} | ${true}                               | ${'License Compliance detected 2 new licenses and policy violations; approval required'}
      `(
        `should show "$expectedSummaryText" if the report contains $givenLicenseReport.length license(s) and contains blacklisted licenses is: $givenReportContainsBlacklistedLicense`,
        ({ givenLicenseReport, givenReportContainsBlacklistedLicense, expectedSummaryText }) => {
          const mockGetters = {
            licenseReport: givenLicenseReport,
            reportContainsBlacklistedLicense: givenReportContainsBlacklistedLicense,
          };

          expect(getters.licenseSummaryText(state, mockGetters)).toBe(expectedSummaryText);
        },
      );
    });

    describe('when there are no licenses on the BASE', () => {
      beforeEach(() => {
        state = createState();
      });

      it.each`
        givenLicenseReport                              | givenReportContainsBlacklistedLicense | expectedSummaryText
        ${[]}                                           | ${false}                              | ${'License Compliance detected no licenses for the source branch only'}
        ${[licenseReportMock[0]]}                       | ${false}                              | ${'License Compliance detected 1 license for the source branch only'}
        ${[licenseReportMock[0], licenseReportMock[0]]} | ${false}                              | ${'License Compliance detected 2 licenses for the source branch only'}
        ${[licenseReportMock[0]]}                       | ${true}                               | ${'License Compliance detected 1 license and policy violation for the source branch only; approval required'}
        ${[licenseReportMock[0], licenseReportMock[0]]} | ${true}                               | ${'License Compliance detected 2 licenses and policy violations for the source branch only; approval required'}
      `(
        `should show "$expectedSummaryText" if the report contains $givenLicenseReport.length license(s) and contains blacklisted licenses is: $givenReportContainsBlacklistedLicense`,
        ({ givenLicenseReport, givenReportContainsBlacklistedLicense, expectedSummaryText }) => {
          const mockGetters = {
            licenseReport: givenLicenseReport,
            reportContainsBlacklistedLicense: givenReportContainsBlacklistedLicense,
          };

          expect(getters.licenseSummaryText(state, mockGetters)).toBe(expectedSummaryText);
        },
      );
    });
  });

  describe('reportContainsBlacklistedLicense', () => {
    it('should be false if the report does not contain blacklisted licenses', () => {
      const mockGetters = {
        licenseReport: [licenseReportMock[0], licenseReportMock[0]],
      };

      expect(getters.reportContainsBlacklistedLicense(state, mockGetters)).toBe(false);
    });

    it('should be true if the report contains blacklisted licenses', () => {
      const mockGetters = {
        licenseReport: [
          licenseReportMock[0],
          { ...licenseReportMock[0], approvalStatus: 'blacklisted' },
        ],
      };

      expect(getters.reportContainsBlacklistedLicense(state, mockGetters)).toBe(true);
    });
  });
});
