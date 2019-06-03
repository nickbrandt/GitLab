import $ from 'jquery';

export default class CiTemplate {
  constructor() {
    this.$input = $('#required_template_name');
    this.$dropdown = $('.js-ci-template-dropdown');
    this.$dropdownToggle = this.$dropdown.find('.dropdown-toggle-text');

    this.initDropdown();
  }

  initDropdown() {
    this.$dropdown.glDropdown({
      data: this.formatDropdownList(),
      selectable: true,
      filterable: true,
      allowClear: true,
      toggleLabel: item => item.name,
      search: {
        fields: ['name'],
      },
      clicked: clickEvent => this.updateInputValue(clickEvent),
      text: item => item.name,
    });

    this.setDropdownToggle();
  }

  formatDropdownList() {
    return {
      Reset: [
        {
          name: 'None',
          id: '',
        },
        'divider',
      ],
      ...this.$dropdown.data('data'),
    };
  }

  setDropdownToggle() {
    const initialValue = this.$input.val();

    if (initialValue) {
      this.$dropdownToggle.text(initialValue);
    }
  }

  updateInputValue({ selectedObj, e }) {
    e.preventDefault();

    this.$input.val(selectedObj.id);
  }
}
