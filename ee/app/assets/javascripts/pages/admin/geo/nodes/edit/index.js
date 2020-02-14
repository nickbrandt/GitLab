import initForm from '../shared/init_form';
import initGeoNodeForm from 'ee/geo_node_form';

if (gon.features?.enableGeoNodeFormJs) {
  document.addEventListener('DOMContentLoaded', initGeoNodeForm);
} else {
  document.addEventListener('DOMContentLoaded', initForm);
}
