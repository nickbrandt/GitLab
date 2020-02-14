import { shallowMount } from '@vue/test-utils';
import ContainerScanningIssueBody from 'ee/vue_shared/security_reports/components/container_scanning_issue_body.vue';

describe('Container Scanning Issue Body', () => {
  let wrapper;

  const createComponent = severity => {
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

  it('renders severity if present on issue', () => {
    createComponent('Low');
    expect(wrapper.find('.report-block-list-issue-description-text').text()).toBe('Low:');
  });

  it('does not render  severity if not present on issue', () => {
    createComponent();
    expect(wrapper.find('.report-block-list-issue-description-text').text()).toBe('');
  });
});
