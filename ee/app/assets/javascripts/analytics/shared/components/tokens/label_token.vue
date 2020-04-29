<script>
import {
  GlFilteredSearchToken,
  GlFilteredSearchSuggestion,
  GlDropdownDivider,
  GlLoadingIcon,
} from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlFilteredSearchToken,
    GlFilteredSearchSuggestion,
    GlDropdownDivider,
    GlLoadingIcon,
  },
  inheritAttrs: false,
  props: {
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
  },
  computed: {
    labels() {
      return this.config.labels;
    },
    filteredLabels() {
      return this.labels
        .filter(label => label.title.toLowerCase().indexOf(this.value.data?.toLowerCase()) !== -1)
        .map(label => ({
          ...label,
          value: this.getEscapedText(label.title),
        }));
    },
  },
  methods: {
    getEscapedText(text) {
      let escapedText = text;
      const hasSpace = text.indexOf(' ') !== -1;
      const hasDoubleQuote = text.indexOf('"') !== -1;

      // Encapsulate value with quotes if it has spaces
      // Known side effect: values's with both single and double quotes
      // won't escape properly
      if (hasSpace) {
        if (hasDoubleQuote) {
          escapedText = `'${text}'`;
        } else {
          // Encapsulate singleQuotes or if it hasSpace
          escapedText = `"${text}"`;
        }
      }

      return escapedText;
    },
  },
  defaultSuggestions: [
    // eslint-disable-next-line @gitlab/require-i18n-strings
    { value: 'None', text: __('None') },
    // eslint-disable-next-line @gitlab/require-i18n-strings
    { value: 'Any', text: __('Any') },
  ],
};
</script>

<template>
  <gl-filtered-search-token :config="config" v-bind="{ ...this.$attrs }" v-on="$listeners">
    <template #view="{ inputValue }">
      <template v-if="config.symbol">{{ config.symbol }}</template>
      {{ inputValue }}
    </template>
    <template #suggestions>
      <gl-filtered-search-suggestion
        v-for="suggestion in $options.defaultSuggestions"
        :key="suggestion.value"
        :value="suggestion.value"
        >{{ suggestion.text }}</gl-filtered-search-suggestion
      >
      <gl-dropdown-divider v-if="config.isLoading || filteredLabels.length" />
      <gl-loading-icon v-if="config.isLoading" />
      <template v-else>
        <gl-filtered-search-suggestion
          v-for="label in filteredLabels"
          ref="labelItem"
          :key="label.id"
          :value="label.value"
        >
          <div class="d-flex">
            <span
              class="d-inline-block mr-2 gl-w-16 gl-h-16 border-radius-small"
              :style="{
                backgroundColor: label.color,
              }"
            ></span>
            <span>{{ label.title }}</span>
          </div>
        </gl-filtered-search-suggestion>
      </template>
    </template>
  </gl-filtered-search-token>
</template>
