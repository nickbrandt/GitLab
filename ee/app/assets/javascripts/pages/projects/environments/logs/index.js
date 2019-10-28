import logsBundle from 'ee/logs/logs_bundle';
import KubernetesLogs from '../../../../kubernetes_logs';

if (gon.features.environmentLogsUseVueUi) {
  document.addEventListener('DOMContentLoaded', logsBundle);
} else {
  document.addEventListener('DOMContentLoaded', () => {
    const kubernetesLogContainer = document.querySelector('.js-kubernetes-logs');
    const kubernetesLog = new KubernetesLogs(kubernetesLogContainer);
    kubernetesLog.getData();
  });
}
