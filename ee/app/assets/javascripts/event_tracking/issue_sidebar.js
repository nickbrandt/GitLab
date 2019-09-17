import Tracking from '~/tracking';

export const initSidebarTracking = () => {
  new Tracking().bind(document.querySelector('.js-issuable-sidebar'));
};

export const trackEvent = (eventType, property, value = '') => {
  Tracking.event(document.body.dataset.page, eventType, {
    label: 'right_sidebar',
    property,
    value,
  });
};
