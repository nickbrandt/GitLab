import initNewFeatureFlags from 'ee/feature_flags/new';

if (gon.features && gon.features.featureFlagsEnvironmentScope) {
  document.addEventListener('DOMContentLoaded', initNewFeatureFlags);
}
