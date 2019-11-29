<script>
import { GlTooltipDirective, GlLoadingIcon, GlEmptyState } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import StageNavItem from './stage_nav_item.vue';
import StageEventList from './stage_event_list.vue';
import StageTableHeader from './stage_table_header.vue';
import AddStageButton from './add_stage_button.vue';
import CustomStageForm from './custom_stage_form.vue';
import { STAGE_ACTIONS } from '../constants';

export default {
  name: 'StageTable',
  components: {
    Icon,
    GlLoadingIcon,
    GlEmptyState,
    StageEventList,
    StageNavItem,
    StageTableHeader,
    AddStageButton,
    CustomStageForm,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    stages: {
      type: Array,
      required: true,
    },
    currentStage: {
      type: Object,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    isEmptyStage: {
      type: Boolean,
      required: true,
    },
    isCreatingCustomStage: {
      type: Boolean,
      required: true,
    },
    isEditingCustomStage: {
      type: Boolean,
      required: true,
    },
    isSavingCustomStage: {
      type: Boolean,
      required: true,
    },
    currentStageEvents: {
      type: Array,
      required: true,
    },
    customStageFormEvents: {
      type: Array,
      required: true,
    },
    labels: {
      type: Array,
      required: true,
    },
    noDataSvgPath: {
      type: String,
      required: true,
    },
    noAccessSvgPath: {
      type: String,
      required: true,
    },
    canEditStages: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    stageName() {
      return this.currentStage ? this.currentStage.title : __('Related Issues');
    },
    shouldDisplayStage() {
      const { currentStageEvents = [], isLoading, isEmptyStage } = this;
      return currentStageEvents.length && !isLoading && !isEmptyStage;
    },
    customStageFormActive() {
      return this.isCreatingCustomStage;
    },
    stageHeaders() {
      return [
        {
          title: s__('ProjectLifecycle|Stage'),
          description: __('The phase of the development lifecycle.'),
          classes: 'stage-header pl-5',
        },
        {
          title: __('Median'),
          description: __(
            'The value lying at the midpoint of a series of observed values. E.g., between 3, 5, 9, the median is 5. Between 3, 5, 7, 8, the median is (5+7)/2 = 6.',
          ),
          classes: 'median-header',
        },
        {
          title: this.stageName,
          description: __('The collection of events added to the data gathered for that stage.'),
          classes: 'event-header pl-3',
          displayHeader: !this.customStageFormActive,
        },
        {
          title: __('Total Time'),
          description: __('The time taken by each data entry gathered by that stage.'),
          classes: 'total-time-header pr-5 text-right',
          displayHeader: !this.customStageFormActive,
        },
      ];
    },
    customStageInitialData() {
      return this.isEditingCustomStage ? this.currentStage : {};
    },
  },
  methods: {
    selectStage(stage) {
      this.$emit(STAGE_ACTIONS.SELECT, stage);
    },
    editStage(stage) {
      this.$emit(STAGE_ACTIONS.EDIT, stage);
    },
    hideStage(stageId) {
      this.$emit(STAGE_ACTIONS.HIDE, { id: stageId, hidden: true });
    },
    removeStage(stageId) {
      this.$emit(STAGE_ACTIONS.REMOVE, stageId);
    },
  },
  STAGE_ACTIONS,
};
</script>
<template>
  <div class="stage-panel-container">
    <div class="card stage-panel">
      <div class="card-header border-bottom-0">
        <nav class="col-headers">
          <ul>
            <stage-table-header
              v-for="({ title, description, classes, displayHeader = true }, i) in stageHeaders"
              v-show="displayHeader"
              :key="`stage-header-${i}`"
              :header-classes="classes"
              :title="title"
              :tooltip-title="description"
            />
          </ul>
        </nav>
      </div>
      <div class="stage-panel-body">
        <nav class="stage-nav">
          <ul>
            <stage-nav-item
              v-for="stage in stages"
              :key="`ca-stage-title-${stage.title}`"
              :title="stage.title"
              :value="stage.value"
              :is-active="!isCreatingCustomStage && stage.id === currentStage.id"
              :can-edit="canEditStages"
              :is-default-stage="!stage.custom"
              @remove="removeStage(stage.id)"
              @hide="hideStage(stage.id)"
              @select="selectStage(stage)"
              @edit="editStage(stage)"
            />
            <add-stage-button
              v-if="canEditStages"
              :active="customStageFormActive"
              @showform="$emit('showAddStageForm')"
            />
          </ul>
        </nav>
        <div class="section stage-events">
          <gl-loading-icon v-if="isLoading" class="mt-4" size="md" />
          <custom-stage-form
            v-else-if="isCreatingCustomStage || isEditingCustomStage"
            :events="customStageFormEvents"
            :labels="labels"
            :is-saving-custom-stage="isSavingCustomStage"
            :initial-fields="customStageInitialData"
            :is-editing-custom-stage="isEditingCustomStage"
            @submit="$emit('submit', $event)"
            @createStage="$emit($options.STAGE_ACTIONS.CREATE, $event)"
            @updateStage="$emit($options.STAGE_ACTIONS.UPDATE, $event)"
          />
          <template v-else>
            <stage-event-list
              v-if="shouldDisplayStage"
              :stage="currentStage"
              :events="currentStageEvents"
            />
            <gl-empty-state
              v-if="isEmptyStage"
              :title="__('We don\'t have enough data to show this stage.')"
              :description="currentStage.emptyStageText"
              :svg-path="noDataSvgPath"
            />
          </template>
        </div>
      </div>
    </div>
  </div>
</template>
