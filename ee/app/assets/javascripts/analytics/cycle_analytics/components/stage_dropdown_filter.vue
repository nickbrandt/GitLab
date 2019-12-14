<script>
import $ from 'jquery';
import _ from 'underscore';
import { GlButton } from '@gitlab/ui';
import { sprintf, s__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'StageDropdownFilter',
  components: {
    Icon,
    GlButton,
  },
  props: {
    stages: {
      type: Array,
      required: true,
    },
    label: {
      type: String,
      required: false,
      default: s__('CycleAnalytics|stage dropdown'),
    },
  },
  data() {
    return {
      selectedStages: this.stages,
    };
  },
  computed: {
    selectedStagesLabel() {
      const { stages, selectedStages } = this;

      if (selectedStages.length === stages.length) {
        return s__('CycleAnalytics|All stages');
      }
      if (selectedStages.length > 1) {
        return sprintf(s__('CycleAnalytics|%{stageCount} stages selected'), {
          stageCount: selectedStages.length,
        });
      }
      if (selectedStages.length === 1) {
        return selectedStages[0].title;
      }

      return s__('CycleAnalytics|No stages selected');
    },
  },
  mounted() {
    $(this.$refs.stagesDropdown).glDropdown({
      selectable: true,
      multiSelect: true,
      clicked: this.onClick.bind(this),
      data: this.formatData.bind(this),
      renderRow: group => this.rowTemplate(group),
      text: stage => stage.title,
    });
  },
  methods: {
    setSelectedStages(selectedObj, isMarking) {
      this.selectedStages = isMarking
        ? this.selectedStages.concat([selectedObj])
        : this.selectedStages.filter(stage => stage.title !== selectedObj.title);
    },
    onClick({ selectedObj, e, isMarking }) {
      e.preventDefault();
      this.setSelectedStages(selectedObj, isMarking);
      this.$emit('selected', this.selectedStages);
    },
    formatData(term, callback) {
      callback(this.stages);
    },
    rowTemplate(stage) {
      return `
          <li>
            <a href='#' class='dropdown-menu-link is-active'>
              ${_.escape(stage.title)}
            </a>
          </li>
        `;
    },
  },
};
</script>

<template>
  <div>
    <div ref="stagesDropdown" class="dropdown dropdown-stages">
      <gl-button
        class="dropdown-menu-toggle wide shadow-none bg-white"
        type="button"
        data-toggle="dropdown"
        aria-expanded="false"
        :aria-label="label"
      >
        {{ selectedStagesLabel }}
        <icon name="chevron-down" />
      </gl-button>
      <div class="dropdown-menu dropdown-menu-selectable dropdown-menu-full-width">
        <div class="dropdown-title text-left">{{ s__('CycleAnalytics|Stages') }}</div>
        <div class="dropdown-content"></div>
      </div>
    </div>
  </div>
</template>
