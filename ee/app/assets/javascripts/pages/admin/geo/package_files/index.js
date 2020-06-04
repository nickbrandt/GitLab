import initGeoReplicable from 'ee/geo_replicable';

if (gon?.features?.geoSelfServiceFramework) {
  document.addEventListener('DOMContentLoaded', initGeoReplicable);
}
