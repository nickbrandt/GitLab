import mountInstanceLicenseApp from 'ee/licenses';

document.addEventListener('DOMContentLoaded', () => {
  const mountElement = document.getElementById('instance-license-mount-element');
  mountInstanceLicenseApp(mountElement);
});
