import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import Flash from '~/flash';

document.addEventListener('DOMContentLoaded', () => {
  const selectElement = document.getElementById('country_select');
  const { countriesEndPoint } = selectElement.dataset;

  axios
    .get(countriesEndPoint)
    .then(({ data }) => {
      // fill #country_select element with array of <option>s
      data.forEach(([name, code]) => {
        const option = document.createElement('option');
        option.value = code;
        option.text = name;

        selectElement.appendChild(option);
      });
    })
    .catch(() => new Flash(__('Error loading countries data.')));
});
