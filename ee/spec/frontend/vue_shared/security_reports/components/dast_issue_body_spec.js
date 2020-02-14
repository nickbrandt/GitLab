import { shallowMount } from '@vue/test-utils';
import DastIssueBody from 'ee/vue_shared/security_reports/components/dast_issue_body.vue';

describe('Dast Issue Body', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(DastIssueBody, {
      propsData: {
        issue: {
          alert: 'X-Content-Type-Options Header Missing',
          severity: 'Low',
          count: '17',
          cweid: '16',
          desc:
            '<p>The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff". </p>',
          title: 'X-Content-Type-Options Header Missing',
          reference:
            '<p>http://msdn.microsoft.com/en-us/library/ie/gg622941%28v=vs.85%29.aspx</p><p>https://www.owasp.org/index.php/List_of_useful_HTTP_headers</p>',
          riskcode: '1',
          riskdesc: 'Low (Medium)',
        },
        status: 'failed',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('matches the snaphot', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });
});
