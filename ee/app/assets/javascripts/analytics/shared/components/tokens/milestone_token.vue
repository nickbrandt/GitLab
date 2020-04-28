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
    milestones() {
      return this.config.milestones;
    },
    filteredMilestones() {
      return this.milestones.filter(
        milestone => milestone.title.toLowerCase().indexOf(this.value.data?.toLowerCase()) !== -1,
      );
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
    // eslint-disable-next-line @gitlab/require-i18n-strings
    { value: 'Upcoming', text: __('Upcoming') },
    // eslint-disable-next-line @gitlab/require-i18n-strings
    { value: 'Started', text: __('Started') },
  ],
};
</script>

<template>
  <gl-filtered-search-token :config="config" v-bind="{ ...this.$attrs }" v-on="$listeners">
    <template #view="{ inputValue }">
      <template v-if="config.symbol">{{ config.symbol }}</template
      >{{ inputValue }}
    </template>
    <template #suggestions>
      <gl-filtered-search-suggestion
        v-for="suggestion in $options.defaultSuggestions"
        :key="suggestion.value"
        :value="suggestion.value"
        >{{ suggestion.text }}</gl-filtered-search-suggestion
      >
      <gl-dropdown-divider v-if="config.isLoading || filteredMilestones.length" />
      <gl-loading-icon v-if="config.isLoading" />
      <template v-else>
        <gl-filtered-search-suggestion
          v-for="milestone in filteredMilestones"
          ref="milestoneItem"
          :key="milestone.id"
          :value="getEscapedText(milestone.title)"
        >
          <div>{{ milestone.title }}</div>
        </gl-filtered-search-suggestion>
      </template>
    </template>
  </gl-filtered-search-token>
</template>
