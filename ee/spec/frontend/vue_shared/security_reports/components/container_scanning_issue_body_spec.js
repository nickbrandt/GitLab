import { shallowMount } from '@vue/test-utils';
import ContainerScanningIssueBody from 'ee/vue_shared/security_reports/components/container_scanning_issue_body.vue';
import SeverityBadge from 'ee/vue_shared/security_reports/components/severity_badge.vue';

describe('Container Scanning Issue Body', () => {
  let wrapper;

  const createComponent = (severity = undefined) => {
    wrapper = shallowMount(ContainerScanningIssueBody, {
      propsData: {
        issue: {
          title: 'CVE-2017-11671',
          namespace: 'debian:8',
          path: 'debian:8',
          severity,
          vulnerability: 'CVE-2017-11671',
        },
        status: 'Failed',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('matches snapshot', () => {
    createComponent('Low');

    expect(wrapper.element).toMatchSnapshot();
  });

  it('does show SeverityBadge if severity is present', () => {
    createComponent('Low');
    expect(wrapper.find(SeverityBadge).props('severity')).toBe('Low');
  });

  it('does not show SeverityBadge if severity is not present', () => {
    createComponent();
    expect(wrapper.contains(SeverityBadge)).toBe(false);
  });
});
