import Vuex from 'vuex';
import { LICENSE_CHECK_NAME, VULNERABILITY_CHECK_NAME } from 'ee/approvals/constants';
import UnconfiguredSecurityRule from 'ee/approvals/components/security_configuration/unconfigured_security_rule.vue';
import createStore from 'ee/security_dashboard/store';
import { mount, createLocalVue } from '@vue/test-utils';
import { GlSkeletonLoading, GlSprintf, GlButton } from '@gitlab/ui';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('UnconfiguredSecurityRule component', () => {
  let wrapper;
  let store;
  let description;

  const findDescription = () => wrapper.find(GlSprintf);
  const findButton = () => wrapper.find(GlButton);

  const vulnCheckMatchRule = {
    name: VULNERABILITY_CHECK_NAME,
    description: 'vuln-check description without enable button',
    enableDescription: 'vuln-check description with enable button',
    docsPath: 'docs/vuln-check',
  };

  const licenseCheckMatchRule = {
    name: LICENSE_CHECK_NAME,
    description: 'license-check description without enable button',
    enableDescription: 'license-check description with enable button',
    docsPath: 'docs/license-check',
  };

  const licenseCheckRule = {
    name: LICENSE_CHECK_NAME,
  };

  const vulnCheckRule = {
    name: VULNERABILITY_CHECK_NAME,
  };

  const features = [
    {
      type: 'sast',
      configured: true,
      description: 'Analyze your source code for known vulnerabilities.',
      link: '/help/user/application_security/sast/index',
      name: 'Static Application Security Testing (SAST)',
    },
    {
      type: 'dast',
      configured: false,
      description: 'Analyze a review version of your web application.',
      link: '/help/user/application_security/dast/index',
      name: 'Dynamic Application Security Testing (DAST)',
    },
    {
      type: 'dependency_scanning',
      configured: true,
      description: 'Analyze your dependencies for known vulnerabilities.',
      link: '/help/user/application_security/dependency_scanning/index',
      name: 'Dependency Scanning',
    },
    {
      type: 'container_scanning',
      configured: true,
      description: 'Check your Docker images for known vulnerabilities.',
      link: '/help/user/application_security/container_scanning/index',
      name: 'Container Scanning',
    },
    {
      type: 'secret_detection',
      configured: false,
      description: 'Analyze your source code and git history for secrets.',
      link: '/help/user/application_security/secret_detection/index',
      name: 'Secret Detection',
    },
    {
      type: 'coverage_fuzzing',
      configured: false,
      description: 'Find bugs in your code with coverage-guided fuzzing',
      link: '/help/user/application_security/coverage_fuzzing/index',
      name: 'Coverage Fuzzing',
    },
    {
      type: 'license_scanning',
      configured: false,
      description: 'Search your project dependencies for their licenses and apply policies.',
      link: '/help/user/compliance/license_compliance/index',
      name: 'License Compliance',
    },
  ];

  const createWrapper = (props = {}) => {
    wrapper = mount(UnconfiguredSecurityRule, {
      localVue,
      store,
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('while loading', () => {
    beforeEach(() => {
      createWrapper({
        rules: [],
        configuration: {},
        matchRule: vulnCheckMatchRule,
        isLoading: true,
      });
    });

    it('should render the loading skeleton', () => {
      expect(wrapper.contains(GlSkeletonLoading)).toBe(true);
    });
  });

  describe('with a configured job that is eligable for Vulnerability-Check', () => {
    describe('with a Vulnerability-Check rule defined', () => {
      beforeEach(() => {
        createWrapper({
          rules: [vulnCheckRule],
          configuration: { features },
          matchRule: vulnCheckMatchRule,
          isLoading: false,
        });
      });

      it('should not render the loading skeleton', () => {
        expect(wrapper.contains(GlSkeletonLoading)).toBe(false);
      });

      it('should not render the row', () => {
        expect(wrapper.find('tr').exists()).toBe(false);
      });
    });

    describe('without a Vulnerability-Check rule defined', () => {
      beforeEach(() => {
        createWrapper({
          rules: [],
          configuration: { features },
          matchRule: vulnCheckMatchRule,
          isLoading: false,
        });
        description = findDescription();
      });

      it('should not render the loading skeleton', () => {
        expect(wrapper.contains(GlSkeletonLoading)).toBe(false);
      });

      it('should render the row with the enable decription and enable button', () => {
        expect(description.exists()).toBe(true);
        expect(description.text()).toBe(vulnCheckMatchRule.enableDescription);
        expect(findButton().exists()).toBe(true);
      });
    });
  });

  describe('with a unconfigured job that is eligable for License-Check', () => {
    describe('with a License-Check rule defined', () => {
      beforeEach(() => {
        createWrapper({
          rules: [licenseCheckRule],
          configuration: { features },
          matchRule: licenseCheckMatchRule,
          isLoading: false,
        });
        description = findDescription();
      });

      it('should not render the loading skeleton', () => {
        expect(wrapper.contains(GlSkeletonLoading)).toBe(false);
      });

      it('should render the row with the decription and no button', () => {
        expect(description.exists()).toBe(true);
        expect(description.text()).toBe(licenseCheckMatchRule.description);
        expect(findButton().exists()).toBe(false);
      });
    });

    describe('without a License-Check rule defined', () => {
      beforeEach(() => {
        createWrapper({
          rules: [],
          configuration: { features },
          matchRule: licenseCheckMatchRule,
          isLoading: false,
        });
        description = findDescription();
      });

      it('should not render the loading skeleton', () => {
        expect(wrapper.contains(GlSkeletonLoading)).toBe(false);
      });

      it('should render the row with the decription and no button', () => {
        expect(description.exists()).toBe(true);
        expect(description.text()).toBe(licenseCheckMatchRule.description);
        expect(findButton().exists()).toBe(false);
      });
    });
  });
});
