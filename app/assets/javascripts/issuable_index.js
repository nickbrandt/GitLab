import $ from 'jquery';
import issuableInitBulkUpdateSidebar from 'ee/issuable_init_bulk_update_sidebar';
import axios from './lib/utils/axios_utils';
import flash from './flash';
import { s__, __ } from './locale';

export default class IssuableIndex {
  constructor(pagePrefix) {
    issuableInitBulkUpdateSidebar.init(pagePrefix);
    IssuableIndex.resetIncomingEmailToken();
  }

  static resetIncomingEmailToken() {
    const $resetToken = $('.incoming-email-token-reset');

    $resetToken.on('click', e => {
      e.preventDefault();

      $resetToken.text(s__('EmailToken|resetting...'));

      axios
        .put($resetToken.attr('href'))
        .then(({ data }) => {
          $('#issuable_email')
            .val(data.new_address)
            .focus();

          $resetToken.text(s__('EmailToken|reset it'));
        })
        .catch(() => {
          flash(__('There was an error when reseting email token.'));

          $resetToken.text(s__('EmailToken|reset it'));
        });
    });
  }
}
