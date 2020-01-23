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
      confidence: 'low',
      priority: 'high',
    });

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders priority if no security and confidence are passed', () => {
    createComponent({
      priority: 'high',
    });

    expect(findDescriptionText().text()).toBe('high:');
  });

  it('renders confidence if no severity is passed', () => {
    createComponent({
      confidence: 'low',
    });

    expect(findDescriptionText().text()).toBe('(Low):');
  });

  it('renders severity if no confidence is passed', () => {
    createComponent({
      severity: 'medium',
    });

    expect(findDescriptionText().text()).toBe('Medium:');
  });

  it('renders severity and confidence if both are passed', () => {
    createComponent({
      severity: 'medium',
      confidence: 'low',
    });

    expect(findDescriptionText().text()).toBe('Medium (Low):');
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
