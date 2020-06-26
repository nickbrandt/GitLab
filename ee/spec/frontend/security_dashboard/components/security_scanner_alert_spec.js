import { mount } from '@vue/test-utils';
import { within, fireEvent } from '@testing-library/dom';
import SecurityScannerAlert from 'ee/security_dashboard/components/security_scanner_alert.vue';

describe('EE Vulnerability Security Scanner Alert', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  const createWrapper = (props = {}) => {
    const defaultProps = {
      notEnabledScanners: [],
      notEnabledHelpPath: '',
      noPipelineRunScanners: [],
      noPipelineRunHelpPath: '',
    };

    wrapper = mount(SecurityScannerAlert, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const withinWrapper = () => within(wrapper.element);
  const findAlert = () => withinWrapper().queryByRole('alert');
  const findById = testId => withinWrapper().getByTestId(testId);

  describe('container', () => {
    it('renders when disabled scanners are detected', () => {
      createWrapper({ notEnabledScanners: ['SAST'], noPipelineRunScanners: [] });

      expect(findAlert()).toBeTruthy();
    });

    it('renders when scanners without pipeline runs are detected', () => {
      createWrapper({ notEnabledScanners: [], noPipelineRunScanners: ['DAST'] });

      expect(findAlert()).toBeTruthy();
    });

    it('does not render when all scanners are enabled', () => {
      createWrapper({ notEnabledScanners: [], noPipelineRunScanners: [] });

      expect(findAlert()).toBe(null);
    });
  });

  describe('dismissal', () => {
    it('renders a button', () => {
      createWrapper({ notEnabledScanners: ['SAST'] });

      expect(withinWrapper().getByRole('button', { name: /dismiss/i })).toBeTruthy();
    });

    it('emits when the button is clicked', async () => {
      createWrapper({ notEnabledScanners: ['SAST'] });

      const dismissalButton = withinWrapper().getByRole('button', { name: /dismiss/i });
      expect(wrapper.emitted('dismiss')).toBeFalsy();

      await fireEvent.click(dismissalButton);

      expect(wrapper.emitted('dismiss')).toHaveLength(1);
    });
  });

  describe('alert text', () => {
    it.each`
      alertType          | givenScanners                                  | expectedTextContained
      ${'notEnabled'}    | ${{ notEnabledScanners: ['SAST'] }}            | ${'SAST is not enabled for this project'}
      ${'notEnabled'}    | ${{ notEnabledScanners: ['SAST', 'DAST'] }}    | ${'SAST, DAST are not enabled for this project'}
      ${'noPipelineRun'} | ${{ noPipelineRunScanners: ['SAST'] }}         | ${'SAST result is not available because a pipeline has not been run since it was enabled'}
      ${'noPipelineRun'} | ${{ noPipelineRunScanners: ['SAST', 'DAST'] }} | ${'SAST, DAST results are not available because a pipeline has not been run since it was enabled'}
    `('renders the correct warning', ({ alertType, givenScanners, expectedTextContained }) => {
      createWrapper({ ...givenScanners });

      expect(findById(alertType).innerText).toContain(expectedTextContained);
    });
  });

  describe('help links', () => {
    it.each`
      alertType          | linkText
      ${'notEnabled'}    | ${'More information'}
      ${'noPipelineRun'} | ${'Run a pipeline'}
    `('link for $alertType scanners renders correctly', ({ alertType, linkText }) => {
      createWrapper({
        [`${alertType}Scanners`]: ['SAST'],
        [`${alertType}HelpPath`]: 'http://foo.com/',
      });

      expect(within(findById(alertType)).getByText(linkText).href).toBe('http://foo.com/');
    });
  });
});
