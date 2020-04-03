import { shallowMount } from '@vue/test-utils';
import AccessibilityIssueBody from '~/reports/accessibility_report/components/accessibility_issue_body.vue';

const issue = {
  name:
    'The accessibility scanning found 2 errors of the following type: WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.NoContent',
  code: 'WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.NoContent',
  status: 'failed',
  className: 'spec.test_spec',
  parsedTECHSCode: 'H91',
  learnMoreUrl: 'https://www.w3.org/TR/WCAG20-TECHS/H91.html',
};

describe('CustomMetricsForm', () => {
  let wrapper;

  const mountComponent = ({ name, code, message, status, className }, isNew = false) => {
    wrapper = shallowMount(AccessibilityIssueBody, {
      propsData: {
        issue: {
          name,
          code,
          message,
          status,
          className,
        },
        isNew,
      },
    });
  };

  const findIsNewBadge = () => wrapper.find({ ref: 'accessibility-issue-is-new-badge' });

  beforeEach(() => {
    mountComponent(issue);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('Parses the TECHS Code from the issue code correctly', () => {
    expect(wrapper.vm.parsedTECHSCode).toEqual(issue.parsedTECHSCode);
  });

  it('Creates the correct URL for learning more about the issue code', () => {
    expect(wrapper.vm.learnMoreUrl).toEqual(issue.learnMoreUrl);
  });

  describe('When issue is new', () => {
    beforeEach(() => {
      mountComponent(issue, true);
    });

    it('Renders the new badge', () => {
      expect(findIsNewBadge().exists()).toEqual(true);
    });
  });

  describe('When issue is not new', () => {
    beforeEach(() => {
      mountComponent(issue, false);
    });

    it('Does not render the new badge', () => {
      expect(findIsNewBadge().exists()).toEqual(false);
    });
  });
});
