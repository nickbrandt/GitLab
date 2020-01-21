<script>
import $ from 'jquery';
import _ from 'underscore';
import { GlButton, GlDropdownDivider, GlSegmentedControl } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import {
  TASKS_BY_TYPE_FILTERS,
  TASKS_BY_TYPE_SUBJECT_ISSUE,
  TASKS_BY_TYPE_SUBJECT_FILTER_OPTIONS,
} from '../constants';

export default {
  name: 'TasksByTypeFilters',
  components: {
    GlButton,
    GlDropdownDivider,
    GlSegmentedControl,
    Icon,
  },
  props: {
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
  },
  mounted() {
    $(this.$refs.labelsDropdown).glDropdown({
      selectable: true,
      multiSelect: true,
      filterable: true,
      search: {
        fields: ['title'],
      },
      clicked: this.onClick.bind(this),
      data: this.formatData.bind(this),
      renderRow: group => this.rowTemplate(group),
      text: label => label.title,
    });
  },
  methods: {
    onClick({ e, selectedObj }) {
      e.preventDefault();
      const { id: value } = selectedObj;
      this.$emit('updateFilter', { filter: TASKS_BY_TYPE_FILTERS.LABEL, value });
    },
    formatData(term, callback) {
      callback(this.labels);
    },
    rowTemplate(label) {
      return `
          <li>
            <a href='#' class='dropdown-menu-link is-active'>
              <span style="background-color: ${
                label.color
              };" class="d-inline-block dropdown-label-box">
              </span>
              ${_.escape(label.title)}
            </a>
          </li>
        `;
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
      <div ref="labelsDropdown" class="dropdown dropdown-labels">
        <gl-button
          class="shadow-none bg-white btn-svg"
          type="button"
          data-toggle="dropdown"
          aria-expanded="false"
          :aria-label="__('CycleAnalytics|Display chart filters')"
        >
          <icon :size="16" name="settings" />
          <icon :size="16" name="chevron-down" />
        </gl-button>
        <div class="dropdown-menu dropdown-menu-selectable dropdown-menu-right">
          <div class="js-tasks-by-type-chart-filters-subject mb-3 mx-3">
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
          <div class="js-tasks-by-type-chart-filters-labels mb-3 mx-3">
            <p class="font-weight-bold text-left my-2">
              {{ s__('CycleAnalytics|Select labels') }}
            </p>
            <div class="dropdown-input px-0">
              <input class="dropdown-input-field" type="search" />
              <icon name="search" class="dropdown-input-search" data-hidden="true" />
            </div>
            <div class="dropdown-content px-0"></div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
