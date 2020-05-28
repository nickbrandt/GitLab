<script>
import { GlNewDropdown, GlNewDropdownHeader, GlNewDropdownItem } from '@gitlab/ui';

import { setUrlParams, queryToObject } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';

const SORTING_TITLE = s__('SortOptions|Sort by:');
const SORTING_OPTIONS = [
  {
    key: 'created_desc',
    text: s__('SortOptions|Last created'),
  },
  {
    key: 'created_asc',
    text: s__('SortOptions|Oldest created'),
  },
];

export default {
  components: {
    GlNewDropdown,
    GlNewDropdownHeader,
    GlNewDropdownItem,
  },
  data() {
    const { sort: selectedOption } = queryToObject(window.location.search);

    return {
      selectedOption: selectedOption || SORTING_OPTIONS[0].key,
    };
  },
  computed: {
    selectedOptionText() {
      return SORTING_OPTIONS.find(option => option.key === this.selectedOption).text;
    },
  },
  methods: {
    getItemLink(key) {
      return setUrlParams({ sort: key });
    },
    isChecked(key) {
      return key === this.selectedOption;
    },
  },
  SORTING_TITLE,
  SORTING_OPTIONS,
};
</script>

<template>
  <div>
    <gl-new-dropdown
      v-model="selectedOption"
      :text="selectedOptionText"
      class="w-100 flex-column flex-lg-row form-group"
    >
      <gl-new-dropdown-header> {{ $options.SORTING_TITLE }}</gl-new-dropdown-header>
      <gl-new-dropdown-item
        v-for="option in $options.SORTING_OPTIONS"
        :key="option.key"
        :is-check-item="true"
        :is-checked="isChecked(option.key)"
        :href="getItemLink(option.key)"
      >
        {{ option.text }}
      </gl-new-dropdown-item>
    </gl-new-dropdown>

    <input type="hidden" name="sort" :value="selectedOption" />
  </div>
</template>
