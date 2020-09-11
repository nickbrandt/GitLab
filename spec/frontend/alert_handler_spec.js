import { setHTMLFixture } from 'helpers/fixtures';
import initAlertHandler from '~/alert_handler';

describe('Alert Handler', () => {
  const ALERT_CLASS = 'gl-alert';
  const BANNER_CLASS = 'gl-banner';
  const CLOSE_LABEL = 'Dismiss';

  const generateHtml = parentClass => `<div class="${parentClass}"><button aria-label="${CLOSE_LABEL}">Dismiss</button></div>`;

  const findFirstAlert = () => document.querySelector(`.${ALERT_CLASS}`);
  const findFirstBanner = () => document.querySelector(`.${BANNER_CLASS}`);
  const findAllAlerts = () => document.querySelectorAll(`.${ALERT_CLASS}`);
  const findFirstCloseButton = () => document.querySelector(`[aria-label="${CLOSE_LABEL}"]`);

  describe('initAlertHandler', () => {
    describe('with one alert', () => {
      beforeEach(() => {
        setHTMLFixture(generateHtml(ALERT_CLASS));
        initAlertHandler();
      });

      it('should render the alert', () => {
        expect(findFirstAlert()).toExist();
      });

      it('should dismiss the alert on click', () => {
        findFirstCloseButton().click();
        expect(findFirstAlert()).not.toExist();
      });
    });

    describe('with two alerts', () => {
      beforeEach(() => {
        setHTMLFixture(generateHtml(ALERT_CLASS) + generateHtml(ALERT_CLASS));
        initAlertHandler();
      });

      it('should render two alerts', () => {
        expect(findAllAlerts()).toHaveLength(2);
      });

      it('should dismiss only one alert on click', () => {
        findFirstCloseButton().click();
        expect(findAllAlerts()).toHaveLength(1);
      });
    });

    describe('with a dismissible banner', () => {
      beforeEach(() => {
        setHTMLFixture(generateHtml(BANNER_CLASS));
        initAlertHandler();
      });

      it('should render the banner', () => {
        expect(findFirstBanner()).toExist();
      });

      it('should dismiss the banner on click', () => {
        findFirstCloseButton().click();
        expect(findFirstBanner()).not.toExist();
      });
    })
  });
});
