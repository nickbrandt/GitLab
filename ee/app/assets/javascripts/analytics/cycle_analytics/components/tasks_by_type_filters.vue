<script>
import {
  GlDropdownDivider,
  GlSegmentedControl,
  GlDropdown,
  GlDropdownItem,
  GlSearchBoxByType,
  GlIcon,
} from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import createFlash from '~/flash';
import { removeFlash } from '../utils';
import {
  TASKS_BY_TYPE_FILTERS,
  TASKS_BY_TYPE_SUBJECT_ISSUE,
  TASKS_BY_TYPE_SUBJECT_FILTER_OPTIONS,
  TASKS_BY_TYPE_MAX_LABELS,
} from '../constants';

export default {
  name: 'TasksByTypeFilters',
  components: {
    GlSegmentedControl,
    GlDropdownDivider,
    GlIcon,
    GlDropdown,
    GlDropdownItem,
    GlSearchBoxByType,
  },
  props: {
    maxLabels: {
      type: Number,
      required: false,
      default: TASKS_BY_TYPE_MAX_LABELS,
    },
    labels: {
      type: Array,
      required: true,
    },
    selectedLabelIds: {
      type: Array,
      required: false,
      default: () => [],
    },
    subjectFilter: {
      type: String,
      required: true,
    },
  },
  data() {
    const { subjectFilter: selectedSubjectFilter } = this;
    return {
      selectedSubjectFilter,
      labelsSearchTerm: '',
    };
  },
  computed: {
    subjectFilterOptions() {
      return Object.entries(TASKS_BY_TYPE_SUBJECT_FILTER_OPTIONS).map(([value, text]) => ({
        text,
        value,
      }));
    },
    selectedFiltersText() {
      const { subjectFilter, selectedLabelIds } = this;
      const subjectFilterText =
        subjectFilter === TASKS_BY_TYPE_SUBJECT_FILTER_OPTIONS[subjectFilter]
          ? TASKS_BY_TYPE_SUBJECT_FILTER_OPTIONS[subjectFilter]
          : TASKS_BY_TYPE_SUBJECT_FILTER_OPTIONS[TASKS_BY_TYPE_SUBJECT_ISSUE];
      return sprintf(
        s__('CycleAnalytics|Showing %{subjectFilterText} and %{selectedLabelsCount} labels'),
        {
          subjectFilterText,
          selectedLabelsCount: selectedLabelIds.length,
        },
      );
    },
    availableLabels() {
      return this.labels.filter(({ name }) =>
        name.toLowerCase().includes(this.labelsSearchTerm.toLowerCase()),
      );
    },
    selectedLabelLimitText() {
      const { selectedLabelIds, maxLabels } = this;
      return sprintf(s__('CycleAnalytics|%{selectedLabelsCount} selected (%{maxLabels} max)'), {
        selectedLabelsCount: selectedLabelIds.length,
        maxLabels,
      });
    },
    maxLabelsSelected() {
      return this.selectedLabelIds.length >= this.maxLabels;
    },
    hasMatchingLabels() {
      return this.availableLabels.length;
    },
  },
  methods: {
    canUpdateLabelFilters(value) {
      // we can always remove a filter
      return this.selectedLabelIds.includes(value) || !this.maxLabelsSelected;
    },
    isLabelSelected(id) {
      return this.selectedLabelIds.includes(id);
    },
    isLabelDisabled(id) {
      return this.maxLabelsSelected && !this.isLabelSelected(id);
    },
    handleLabelSelected(value) {
      removeFlash('notice');
      if (this.canUpdateLabelFilters(value)) {
        this.$emit('updateFilter', { filter: TASKS_BY_TYPE_FILTERS.LABEL, value });
      } else {
        const { maxLabels } = this;
        const message = sprintf(
          s__('CycleAnalytics|Only %{maxLabels} labels can be selected at this time'),
          { maxLabels },
        );
        createFlash(message, 'notice');
      }
    },
  },
  TASKS_BY_TYPE_FILTERS,
};
</script>

<template>
  <div
    class="js-tasks-by-type-chart-filters d-flex flex-row justify-content-between align-items-center"
  >
    <div class="flex-column">
      <h4>{{ s__('CycleAnalytics|Tasks by type') }}</h4>
      <p>{{ selectedFiltersText }}</p>
    </div>
    <div class="flex-column">
      <gl-dropdown
        aria-expanded="false"
        :aria-label="__('CycleAnalytics|Display chart filters')"
        right
      >
        <template #button-content>
          <gl-icon class="vertical-align-top" name="settings" />
          <gl-icon name="chevron-down" />
        </template>
        <div class="mb-3 px-3">
          <p class="font-weight-bold text-left mb-2">{{ s__('CycleAnalytics|Show') }}</p>
          <gl-segmented-control
            v-model="selectedSubjectFilter"
            :options="subjectFilterOptions"
            @input="
              value =>
                $emit('updateFilter', { filter: $options.TASKS_BY_TYPE_FILTERS.SUBJECT, value })
            "
          />
        </div>
        <gl-dropdown-divider />
        <div class="mb-3 px-3">
          <p class="font-weight-bold text-left my-2">
            {{ s__('CycleAnalytics|Select labels') }}
            <br /><small>{{ selectedLabelLimitText }}</small>
          </p>
          <gl-search-box-by-type v-model.trim="labelsSearchTerm" class="mb-2" />
          <gl-dropdown-item
            v-for="label in availableLabels"
            :key="label.id"
            :disabled="isLabelDisabled(label.id)"
            :class="{
              'pl-4': !isLabelSelected(label.id),
              'cursor-not-allowed': isLabelDisabled(label.id),
            }"
            @click="() => handleLabelSelected(label.id)"
          >
            <gl-icon
              v-if="isLabelSelected(label.id)"
              class="text-gray-700 mr-1 vertical-align-middle"
              name="mobile-issue-close"
            />
            <span
              :style="{ 'background-color': label.color }"
              class="d-inline-block dropdown-label-box"
            ></span>
            {{ label.name }}
          </gl-dropdown-item>
          <div v-show="!hasMatchingLabels" class="text-secondary">
            {{ __('No matching labels') }}
          </div>
        </div>
      </gl-dropdown>
    </div>
  </div>
</template>
