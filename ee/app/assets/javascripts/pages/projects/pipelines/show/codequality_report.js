import Vue from 'vue';
import CodequalityReportApp from 'ee/codequality_report/codequality_report.vue';
import Translate from '~/vue_shared/translate';

Vue.use(Translate);

export default () => {
  const codequalityTab = document.getElementById('js-pipeline-codequality-report');

  if (codequalityTab) {
    const { codequalityReportDownloadPath, blobPath } = codequalityTab.dataset;

    // eslint-disable-next-line no-new
    new Vue({
      el: codequalityTab,
      components: {
        CodequalityReportApp,
      },
      render(createElement) {
        return createElement('codequality-report-app', {
          props: {
            codequalityReportDownloadPath,
            blobPath,
          },
        });
      },
    });
  }
};
