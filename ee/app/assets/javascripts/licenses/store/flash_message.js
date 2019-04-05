import createFlash from '~/flash';
import { __ } from '~/locale';

const FLASH_MESSAGES = {
  fetchLicenses: {
    403: __('Fetching licenses failed. You are not permitted to perform this action.'),
    404: __('Fetching licenses failed. The request endpoint was not found.'),
    default: __('Fetching licenses failed.'),
  },
  fetchDeleteLicense: {
    403: __('Deleting the license failed. You are not permitted to perform this action.'),
    404: __('Deleting the license failed. The license was not found.'),
    default: __('Deleting the license failed.'),
  },
};

export default function flashMessage(action, status) {
  const messages = FLASH_MESSAGES[action];

  createFlash(messages[status] || messages.default);
}
