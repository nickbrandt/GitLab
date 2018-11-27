import Vue from 'vue';
import csrf from '~/lib/utils/csrf';
import DeleteCustomMetricModal from './delete_custom_metric_modal.vue';

const initDeleteCustomMetricLogic = () => {
  const deleteCustomMetricModalEl = document.getElementById('delete-custom-metric-modal-wrapper');

  if (deleteCustomMetricModalEl) {
    const { deleteMetricUrl } = deleteCustomMetricModalEl.dataset;

    // eslint-disable-next-line no-new
    new Vue({
      el: deleteCustomMetricModalEl,
      components: {
        DeleteCustomMetricModal,
      },
      methods: {},
      render(createElement) {
        return createElement('delete-custom-metric-modal', {
          props: { deleteMetricUrl, csrfToken: csrf.token },
        });
      },
    });
  }
};

document.addEventListener('DOMContentLoaded', initDeleteCustomMetricLogic);
