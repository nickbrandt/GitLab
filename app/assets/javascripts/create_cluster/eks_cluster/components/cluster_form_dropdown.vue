<script>
import DropdownSearchInput from '~/vue_shared/components/dropdown/dropdown_search_input.vue';
import DropdownHiddenInput from '~/vue_shared/components/dropdown/dropdown_hidden_input.vue';
import DropdownButton from '~/vue_shared/components/dropdown/dropdown_button.vue';
import Icon from '~/vue_shared/components/icon.vue';

const toArray = value => (Array.isArray(value) ? value : [value]);
const matchItem = (valueProp, item, value) => item[valueProp] === value;
const findItems = (valueProp, items, values) =>
  items.filter(item => values.some(value => matchItem(valueProp, item, value)));
const itemsProp = (items, prop) => items.map(item => item[prop]);

export default {
  components: {
    DropdownButton,
    DropdownSearchInput,
    DropdownHiddenInput,
    Icon,
  },
  props: {
    fieldName: {
      type: String,
      required: false,
      default: '',
    },
    placeholder: {
      type: String,
      required: false,
      default: '',
    },
    defaultValue: {
      type: String,
      required: false,
      default: '',
    },
    value: {
      type: [Object, Array, String],
      required: false,
      default: () => null,
    },
    labelProperty: {
      type: String,
      required: false,
      default: 'name',
    },
    valueProperty: {
      type: String,
      required: false,
      default: 'value',
    },
    items: {
      type: Array,
      required: false,
      default: () => [],
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    loadingText: {
      type: String,
      required: false,
      default: '',
    },
    disabledText: {
      type: String,
      required: false,
      default: '',
    },
    hasErrors: {
      type: Boolean,
      required: false,
      default: false,
    },
    multiple: {
      type: Boolean,
      required: false,
      default: false,
    },
    errorMessage: {
      type: String,
      required: false,
      default: '',
    },
    searchFieldPlaceholder: {
      type: String,
      required: false,
      default: '',
    },
    emptyText: {
      type: String,
      required: false,
      default: '',
    },
    searchFn: {
      type: Function,
      required: false,
      default: searchQuery => item => item.name.toLowerCase().indexOf(searchQuery) > -1,
    },
  },
  data() {
    return {
      selectedItems: this.updateSelectedItems(),
      searchQuery: '',
    };
  },
  computed: {
    toggleText() {
      if (this.loading && this.loadingText) {
        return this.loadingText;
      }

      if (this.disabled && this.disabledText) {
        return this.disabledText;
      }

      if (!this.selectedItems.length) {
        return this.placeholder;
      }

      return this.selectedItemsLabels;
    },
    results() {
      if (!this.items) {
        return [];
      }

      return this.items.filter(this.searchFn(this.searchQuery));
    },
    selectedItemsLabels() {
      return itemsProp(this.selectedItems, this.labelProperty).join(', ');
    },
    selectedItemsValues() {
      return itemsProp(this.selectedItems, this.valueProperty).join(', ');
    },
  },
  watch: {
    value() {
      this.selectedItems = this.updateSelectedItems();
    },
    items() {
      this.selectedItems = this.updateSelectedItems();
    },
  },
  methods: {
    updateSelectedItems() {
      return findItems(this.valueProperty, this.getItemsOrEmptyList(), toArray(this.value));
    },
    getItemsOrEmptyList() {
      return this.items || [];
    },
    select(item) {
      this.selectedItems = [item];
      this.$emit('input', item[this.valueProperty]);
    },
    selectMultiple(item) {
      if (this.isSelected(item)) {
        this.selectedItems.splice(this.selectedItems.indexOf(item), 1);
      } else {
        this.selectedItems.push(item);
      }

      this.$emit('input', itemsProp(this.selectedItems, this.valueProperty));
    },
    isSelected(item) {
      return this.selectedItems.includes(item);
    },
  },
};
</script>

<template>
  <div>
    <div class="js-gcp-machine-type-dropdown dropdown">
      <dropdown-hidden-input :name="fieldName" :value="selectedItemsValues" />
      <dropdown-button
        :class="{ 'border-danger': hasErrors }"
        :is-disabled="disabled"
        :is-loading="loading"
        :toggle-text="toggleText"
      />
      <div class="dropdown-menu dropdown-select">
        <dropdown-search-input v-model="searchQuery" :placeholder-text="searchFieldPlaceholder" />
        <div class="dropdown-content">
          <ul>
            <li v-if="!results.length">
              <span class="js-empty-text menu-item">{{ emptyText }}</span>
            </li>
            <li v-for="item in results" :key="item.id">
              <button
                v-if="multiple"
                class="js-dropdown-item d-flex align-items-center"
                type="button"
                @click.stop.prevent="selectMultiple(item)"
              >
                <icon
                  :class="[{ invisible: !isSelected(item) }, 'mr-1']"
                  name="mobile-issue-close"
                />
                <slot name="item" :item="item">{{ item.name }}</slot>
              </button>
              <button v-else class="js-dropdown-item" type="button" @click.prevent="select(item)">
                <slot name="item" :item="item">{{ item.name }}</slot>
              </button>
            </li>
          </ul>
        </div>
      </div>
    </div>
    <span
      v-if="hasErrors && errorMessage"
      :class="[
        'form-text js-eks-dropdown-error-message',
        {
          'text-danger': hasErrors,
          'text-muted': !hasErrors,
        },
      ]"
      >{{ errorMessage }}</span
    >
  </div>
</template>
