/* eslint-disable no-shadow, no-else-return */

import $ from 'jquery';
import '~/gl_dropdown';

function WeightSelect(els, options = {}) {
  const $els = $(els || '.js-weight-select');

  $els.each((i, dropdown) => {
    const $dropdown = $(dropdown);
    const $selectbox = $dropdown.closest('.selectbox');
    const $block = $selectbox.closest('.block');
    const $value = $block.find('.value');
    $block.find('.block-loading').fadeOut();
    const fieldName = options.fieldName || $dropdown.data('fieldName');
    const inputField = $dropdown.closest('.selectbox').find(`input[name='${fieldName}']`);

    if (Object.keys(options).includes('selected')) {
      inputField.val(options.selected);
    }

    return $dropdown.glDropdown({
      selectable: true,
      fieldName,
      toggleLabel(selected, el) {
        return $(el).data('id');
      },
      hidden() {
        $selectbox.hide();
        return $value.css('display', '');
      },
      id(obj, el) {
        if ($(el).data('none') == null) {
          return $(el).data('id');
        } else {
          return '';
        }
      },
      clicked(glDropdownEvt) {
        const { e } = glDropdownEvt;
        let selected = glDropdownEvt.selectedObj;
        const inputField = $dropdown.closest('.selectbox').find(`input[name='${fieldName}']`);

        if (options.handleClick) {
          e.preventDefault();
          selected = inputField.val();
          options.handleClick(selected);
        } else if ($dropdown.is('.js-issuable-form-weight')) {
          e.preventDefault();
        }
      },
    });
  });
}

export default WeightSelect;
