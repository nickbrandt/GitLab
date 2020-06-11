import initGeoSettingsForm from 'ee/geo_settings';

if (gon.features?.enableGeoSettingsFormJs) {
  document.addEventListener('DOMContentLoaded', initGeoSettingsForm);
}
