import PayloadPreviewer from '~/pages/admin/application_settings/payload_previewer';
import baseSetup from '~/admin/application_settings/setup_metrics_and_profiling';

export default () => {
  baseSetup();

  new PayloadPreviewer(
    document.querySelector('.js-seat-link-payload-trigger'),
    document.querySelector('.js-seat-link-payload'),
  ).init();
};
