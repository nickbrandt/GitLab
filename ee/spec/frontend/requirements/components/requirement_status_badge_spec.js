import { GlBadge, GlIcon, GlTooltip } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import RequirementStatusBadge from 'ee/requirements/components/requirement_status_badge.vue';
import { mockTestReport, mockTestReportFailed, mockTestReportMissing } from '../mock_data';

const createComponent = ({
  testReport = mockTestReport,
  lastTestReportManuallyCreated = false,
} = {}) =>
  shallowMount(RequirementStatusBadge, {
    propsData: {
      testReport,
      lastTestReportManuallyCreated,
    },
  });

const findGlBadge = (wrapper) => wrapper.find(GlBadge);
const findGlTooltip = (wrapper) => wrapper.find(GlTooltip);

const successBadgeProps = {
  variant: 'success',
  icon: 'status_success',
  text: 'satisfied',
  tooltipTitle: 'Passed on',
};

const failedBadgeProps = {
  variant: 'danger',
  icon: 'status_failed',
  text: 'failed',
  tooltipTitle: 'Failed on',
};

describe('RequirementStatusBadge', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('testReportBadge', () => {
      it('returns object containing variant, icon, text and tooltipTitle when status is "PASSED"', () => {
        expect(wrapper.vm.testReportBadge).toEqual(successBadgeProps);
      });

      it('returns object containing variant, icon, text and tooltipTitle when status is "FAILED"', () => {
        wrapper.setProps({
          testReport: mockTestReportFailed,
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.testReportBadge).toEqual(failedBadgeProps);
        });
      });

      it('returns object containing variant, icon, text and tooltipTitle when status missing', () => {
        wrapper.setProps({
          testReport: mockTestReportMissing,
        });

        return wrapper.vm.$nextTick(() => {
          expect(wrapper.vm.testReportBadge).toEqual({
            variant: 'warning',
            icon: 'status_warning',
            text: 'missing',
            tooltipTitle: '',
          });
        });
      });
    });
  });

  describe('template', () => {
    describe.each`
      testReport              | badgeProps
      ${mockTestReport}       | ${successBadgeProps}
      ${mockTestReportFailed} | ${failedBadgeProps}
    `(`when the last test report's been automatically created`, ({ testReport, badgeProps }) => {
      beforeEach(() => {
        wrapper = createComponent({
          testReport,
          lastTestReportManuallyCreated: false,
        });
      });

      describe(`when test report status is ${testReport.state}`, () => {
        it(`renders GlBadge component`, () => {
          const badgeEl = findGlBadge(wrapper);

          expect(badgeEl.exists()).toBe(true);
          expect(badgeEl.props('variant')).toBe(badgeProps.variant);
          expect(badgeEl.text()).toBe(badgeProps.text);
          expect(badgeEl.find(GlIcon).exists()).toBe(true);
          expect(badgeEl.find(GlIcon).props('name')).toBe(badgeProps.icon);
        });

        it('renders GlTooltip component', () => {
          const tooltipEl = findGlTooltip(wrapper);

          expect(tooltipEl.exists()).toBe(true);
          expect(tooltipEl.find('b').text()).toBe(badgeProps.tooltipTitle);
          expect(tooltipEl.find('div').text()).toBe('Jun 4, 2015 10:55am GMT+0000');
        });
      });
    });

    describe(`when the last test report's been manually created`, () => {
      it('renders GlBadge component when status is "PASSED"', () => {
        wrapper = createComponent({ lastTestReportManuallyCreated: true });

        expect(findGlBadge(wrapper).exists()).toBe(true);
        expect(findGlBadge(wrapper).text()).toBe('satisfied');
      });

      it('does not render GlBadge component when status is "FAILED"', () => {
        wrapper = createComponent({
          testReport: mockTestReportFailed,
          lastTestReportManuallyCreated: true,
        });

        expect(findGlBadge(wrapper).exists()).toBe(false);
      });
    });
  });
});
