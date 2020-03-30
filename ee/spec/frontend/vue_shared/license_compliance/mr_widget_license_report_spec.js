import Vuex from 'vuex';
import LicenseManagement from 'ee/vue_shared/license_compliance/mr_widget_license_report.vue';
import ReportSection from '~/reports/components/report_section.vue';
import ReportItem from '~/reports/components/report_item.vue';
import { LOADING, ERROR, SUCCESS } from 'ee/vue_shared/security_reports/store/constants';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { TEST_HOST } from 'spec/test_constants';
import {
  approvedLicense,
  blacklistedLicense,
  licenseReport as licenseReportMock,
  generateReportGroup,
} from './mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('License Report MR Widget', () => {
  const apiUrl = `${TEST_HOST}/license_management`;
  const securityApprovalsHelpPagePath = `${TEST_HOST}/path/to/security/approvals/help`;
  let wrapper;

  const defaultState = {
    managedLicenses: [approvedLicense, blacklistedLicense],
    currentLicenseInModal: licenseReportMock[0],
    isLoadingManagedLicenses: true,
  };

  const defaultGetters = {
    isLoading() {
      return false;
    },
    licenseReport() {
      return licenseReportMock;
    },
    licenseSummaryText() {
      return 'FOO';
    },
    reportContainsBlacklistedLicense() {
      return false;
    },
    licenseReportGroups() {
      return [];
    },
  };

  const defaultProps = {
    loadingText: 'LOADING',
    errorText: 'ERROR',
    licensesApiPath: `${TEST_HOST}/parsed_license_report.json`,
    canManageLicenses: true,
    licenseManagementSettingsPath: `${TEST_HOST}/lm_settings`,
    fullReportPath: `${TEST_HOST}/path/to/the/full/report`,
    apiUrl,
    securityApprovalsHelpPagePath,
  };

  const defaultActions = {
    setAPISettings: () => {},
    fetchManagedLicenses: () => {},
    fetchParsedLicenseReport: () => {},
  };

  const mountComponent = ({
    props = defaultProps,
    getters = defaultGetters,
    state = defaultState,
    actions = defaultActions,
  } = {}) => {
    const store = new Vuex.Store({
      modules: {
        licenseManagement: {
          namespaced: true,
          state,
          getters,
          actions,
        },
      },
    });
    return shallowMount(LicenseManagement, {
      localVue,
      propsData: props,
      store,
      stubs: { ReportSection },
    });
  };

  beforeEach(() => {
    wrapper = mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('computed', () => {
    describe('hasLicenseReportIssues', () => {
      it('should be false, if the report is empty', () => {
        const getters = {
          ...defaultGetters,
          licenseReport() {
            return [];
          },
        };
        wrapper = mountComponent({ getters });

        expect(wrapper.vm.hasLicenseReportIssues).toBe(false);
      });

      it('should be true, if the report is not empty', () => {
        expect(wrapper.vm.hasLicenseReportIssues).toBe(true);
      });
    });

    describe('licenseReportStatus', () => {
      it('should be `LOADING`, if the report is loading', () => {
        const getters = {
          ...defaultGetters,
          isLoading() {
            return true;
          },
        };
        wrapper = mountComponent({ getters });

        expect(wrapper.vm.licenseReportStatus).toBe(LOADING);
      });

      it('should be `ERROR`, if the report is has an error', () => {
        const state = { ...defaultState, loadLicenseReportError: new Error('test') };
        wrapper = mountComponent({ state });

        expect(wrapper.vm.licenseReportStatus).toBe(ERROR);
      });

      it('should be `SUCCESS`, if the report is successful', () => {
        expect(wrapper.vm.licenseReportStatus).toBe(SUCCESS);
      });
    });

    describe('showActionButtons', () => {
      const { fullReportPath, licenseManagementSettingsPath, ...otherProps } = defaultProps;

      it('should be true if fullReportPath AND licenseManagementSettingsPath prop are provided', () => {
        const props = { ...otherProps, fullReportPath, licenseManagementSettingsPath };
        wrapper = mountComponent({ props });

        expect(wrapper.vm.showActionButtons).toBe(true);
      });

      it('should be true if only licenseManagementSettingsPath is provided', () => {
        const props = { ...otherProps, fullReportPath: null, licenseManagementSettingsPath };
        wrapper = mountComponent({ props });

        expect(wrapper.vm.showActionButtons).toBe(true);
      });

      it('should be true if only fullReportPath is provided', () => {
        const props = {
          ...otherProps,
          fullReportPath,
          licenseManagementSettingsPath: null,
        };
        wrapper = mountComponent({ props });

        expect(wrapper.vm.showActionButtons).toBe(true);
      });

      it('should be false if fullReportPath and licenseManagementSettingsPath prop are not provided', () => {
        const props = {
          ...otherProps,
          fullReportPath: null,
          licenseManagementSettingsPath: null,
        };
        wrapper = mountComponent({ props });

        expect(wrapper.vm.showActionButtons).toBe(false);
      });
    });
  });

  describe('report section', () => {
    it('should render correctly', () => {
      const mockReportGroups = [generateReportGroup()];

      wrapper = mountComponent({
        getters: {
          ...defaultGetters,
          licenseReportGroups() {
            return mockReportGroups;
          },
        },
      });

      expect(wrapper.find(ReportSection).element).toMatchSnapshot();
    });

    it.each`
      givenStatuses                       | expectedNumberOfReportHeadings
      ${[]}                               | ${0}
      ${['failed', 'neutral']}            | ${2}
      ${['failed', 'neutral', 'success']} | ${3}
    `(
      'given reports for: $givenStatuses it has $expectedNumberOfReportHeadings report headings',
      ({ givenStatuses, expectedNumberOfReportHeadings }) => {
        const mockReportGroups = givenStatuses.map(status => generateReportGroup({ status }));

        wrapper = mountComponent({
          getters: {
            ...defaultGetters,
            licenseReportGroups() {
              return mockReportGroups;
            },
          },
        });

        expect(wrapper.findAll({ ref: 'reportHeading' }).length).toBe(
          expectedNumberOfReportHeadings,
        );
      },
    );

    it.each([0, 1, 2])(
      'should include %d report items when section has %# licenses',
      numberOfLicenses => {
        const mockReportGroups = [
          generateReportGroup({
            numberOfLicenses,
          }),
        ];

        wrapper = mountComponent({
          getters: {
            ...defaultGetters,
            licenseReportGroups() {
              return mockReportGroups;
            },
          },
        });

        expect(wrapper.findAll(ReportItem).length).toBe(numberOfLicenses);
      },
    );
  });

  describe('`View full report` button', () => {
    const selector = '.js-full-report';

    it('should be rendered when fullReportPath prop is provided', () => {
      const linkEl = wrapper.find(selector);

      expect(linkEl.exists()).toBe(true);
      expect(linkEl.attributes('href')).toEqual(defaultProps.fullReportPath);
      expect(linkEl.text()).toBe('View full report');
    });

    it('should not be rendered when fullReportPath prop is not provided', () => {
      const props = { ...defaultProps, fullReportPath: null };
      wrapper = mountComponent({ props });

      expect(wrapper.contains(selector)).toBe(false);
    });
  });

  describe('`Manage licenses` button', () => {
    const selector = '.js-manage-licenses';

    it('should be rendered when licenseManagementSettingsPath prop is provided', () => {
      const linkEl = wrapper.find(selector);

      expect(linkEl.exists()).toBe(true);
      expect(linkEl.attributes('href')).toEqual(defaultProps.licenseManagementSettingsPath);
      expect(linkEl.text()).toBe('Manage licenses');
    });

    it('should not be rendered when licenseManagementSettingsPath prop is not provided', () => {
      const props = { ...defaultProps, licenseManagementSettingsPath: null };
      wrapper = mountComponent({ props });

      expect(wrapper.contains(selector)).toBe(false);
    });
  });

  it('should render set approval modal', () => {
    expect(wrapper.find('#modal-set-license-approval')).not.toBeNull();
  });

  it('should init store after mount', () => {
    const actions = {
      setAPISettings: jest.fn(() => {}),
      fetchParsedLicenseReport: jest.fn(() => {}),
    };
    wrapper = mountComponent({ actions });

    expect(actions.setAPISettings).toHaveBeenCalledWith(
      expect.any(Object),
      {
        apiUrlManageLicenses: apiUrl,
        licensesApiPath: defaultProps.licensesApiPath,
        canManageLicenses: true,
      },
      undefined,
    );

    expect(actions.fetchParsedLicenseReport).toHaveBeenCalledWith(
      expect.any(Object),
      undefined,
      undefined,
    );
  });

  describe('approval status', () => {
    const findSecurityApprovalHelpLink = () => wrapper.find('.js-security-approval-help-link');

    it('does not show a link to security approval help page if report does not contain blacklisted licenses', () => {
      expect(findSecurityApprovalHelpLink().exists()).toBe(false);
    });

    it('shows a link to security approval help page if report contains blacklisted licenses', () => {
      const getters = {
        ...defaultGetters,
        reportContainsBlacklistedLicense() {
          return true;
        },
      };
      wrapper = mountComponent({ getters });
      const securityApprovalHelpLink = findSecurityApprovalHelpLink();

      expect(findSecurityApprovalHelpLink().exists()).toBe(true);
      expect(securityApprovalHelpLink.attributes('href')).toBe(securityApprovalsHelpPagePath);
    });
  });
});
