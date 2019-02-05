import initEditFeatureFlags from 'ee/feature_flags/edit';

if (gon.features && gon.features.featureFlagsEnvironmentScope) {
  document.addEventListener('DOMContentLoaded', initEditFeatureFlags);
}
