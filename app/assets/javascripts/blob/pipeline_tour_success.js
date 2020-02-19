import $ from 'jquery';
import Cookies from 'js-cookie';

export default class PipelineTourSuccess {
  constructor() {
    this.successModal = $('.js-success-pipeline-modal');
  }

  showModal() {
    if (!this.successModal.length) return;
    this.successModal.modal('show');

    this.disableModalFromRenderingAgain();
  }

  disableModalFromRenderingAgain() {
    Cookies.remove(this.successModal.data('commit-cookie'));
  }
}
