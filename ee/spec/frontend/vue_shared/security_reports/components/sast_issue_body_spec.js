import { shallowMount } from '@vue/test-utils';
import { STATUS_FAILED } from '~/reports/constants';
import SastIssueBody from 'ee/vue_shared/security_reports/components/sast_issue_body.vue';
import ReportLink from '~/reports/components/report_link.vue';

describe('Sast Issue Body', () => {
  let wrapper;

  const findDescriptionText = () => wrapper.find('.report-block-list-issue-description-text');
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
      severity: 'medium',
      priority: 'high',
    });

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders priority if no security are passed', () => {
    createComponent({
      priority: 'high',
    });

    expect(findDescriptionText().text()).toBe('high:');
  });

  it('renders severity', () => {
    createComponent({
      severity: 'medium',
    });

    expect(findDescriptionText().text()).toBe('Medium:');
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
