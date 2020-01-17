import Vue from 'vue';
import CodequalityReportApp from 'ee/codequality_report/codequality_report.vue';
import Translate from '~/vue_shared/translate';
import createStore from 'ee/codequality_report/store';

Vue.use(Translate);

export default () => {
  const codequalityTab = document.getElementById('js-pipeline-codequality-report');

  if (codequalityTab) {
    const { codequalityReportDownloadPath, blobPath } = codequalityTab.dataset;

    const store = createStore({ endpoint: codequalityReportDownloadPath, blobPath });
    store.dispatch('fetchReport');

    // eslint-disable-next-line no-new
    new Vue({
      el: codequalityTab,
      components: {
        CodequalityReportApp,
      },
      store,
      render: createElement => createElement('codequality-report-app'),
    });
  }
};
