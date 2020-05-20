import Tracking from '~/tracking';

const trackLogs = ({ label, value }) =>
  Tracking.event(document.body.dataset.page, 'logs_view', {
    label,
    property: 'count',
    value,
  });

export default trackLogs;
