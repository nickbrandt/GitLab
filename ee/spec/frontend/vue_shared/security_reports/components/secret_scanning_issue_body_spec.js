import { shallowMount } from '@vue/test-utils';
import SecretScanningIssueBody from 'ee/vue_shared/security_reports/components/secret_scanning_issue_body.vue';
import SeverityBadge from 'ee/vue_shared/security_reports/components/severity_badge.vue';

describe('Secret Scanning Issue Body', () => {
  let wrapper;

  const createComponent = (severity = undefined) => {
    wrapper = shallowMount(SecretScanningIssueBody, {
      propsData: {
        issue: {
          title: 'AWS SecretKey Found',
          severity,
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
    createComponent('Critical');

    expect(wrapper.element).toMatchSnapshot();
  });

  it('does show SeverityBadge if severity is present', () => {
    createComponent('Critical');
    expect(wrapper.find(SeverityBadge).props('severity')).toBe('Critical');
  });

  it('does not show SeverityBadge if severity is not present', () => {
    createComponent();
    expect(wrapper.contains(SeverityBadge)).toBe(false);
  });
});
