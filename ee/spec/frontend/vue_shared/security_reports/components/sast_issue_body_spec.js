import { shallowMount } from '@vue/test-utils';
import { STATUS_FAILED } from '~/reports/constants';
import SastIssueBody from 'ee/vue_shared/security_reports/components/sast_issue_body.vue';
import SeverityBadge from 'ee/vue_shared/security_reports/components/severity_badge.vue';
import ReportLink from '~/reports/components/report_link.vue';

describe('Sast Issue Body', () => {
  let wrapper;

  const findReportLink = () => wrapper.find(ReportLink);

  const createComponent = issue => {
    wrapper = shallowMount(SastIssueBody, {
      propsData: {
        issue,
        status: STATUS_FAILED,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('matches snapshot', () => {
    createComponent({
      severity: 'Medium',
    });

    expect(wrapper.element).toMatchSnapshot();
  });

  it('does show SeverityBadge if severity is present', () => {
    createComponent({
      severity: 'Medium',
    });

    expect(wrapper.find(SeverityBadge).props('severity')).toBe('Medium');
  });

  it('does not show SeverityBadge if severity is not present', () => {
    createComponent({});
    expect(wrapper.contains(SeverityBadge)).toBe(false);
  });

  it('does not render report link if no path is passed', () => {
    createComponent({});

    expect(findReportLink().exists()).toBe(false);
  });

  it('renders report link if path is passed', () => {
    createComponent({ path: 'test-path' });

    expect(findReportLink().exists()).toBe(true);
  });
});
