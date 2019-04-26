import initDependenciesApp from 'ee/dependencies';

document.addEventListener('DOMContentLoaded', () => {
  if (!gon.features.billOfMaterials) {
    return;
  }

  initDependenciesApp();
});
