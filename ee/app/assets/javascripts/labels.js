import Labels from '~/labels';
import $ from 'jquery';

class LabelsEE extends Labels {
  addBinding() {
    $(document).on('input', 'input.js-label-title', this.showSuggestedText);
    super.addBinding();
  }

  showSuggestedText() {
    const title = $(this).val();

    const $parentEl = $('.label-form');
    const hasKeyValue = $parentEl.find('.js-has-scoped-labels');
    const useKeyValue = $parentEl.find('.js-use-scoped-labels');

    const isKeyVal = title.indexOf('::') === -1;
    hasKeyValue.toggleClass('hidden', isKeyVal);
    useKeyValue.toggleClass('hidden', !isKeyVal);
  }
}

export default LabelsEE;
