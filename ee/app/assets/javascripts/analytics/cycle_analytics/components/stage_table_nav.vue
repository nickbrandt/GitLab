<script>
import Sortable from 'sortablejs';
import StageNavItem from './stage_nav_item.vue';
import AddStageButton from './add_stage_button.vue';
import { STAGE_ACTIONS } from '../constants';
import { NO_DRAG_CLASS } from '../../shared/constants';
import sortableDefaultOptions from '../../shared/mixins/sortable_default_options';

export default {
  name: 'StageTableNav',
  components: {
    AddStageButton,
    StageNavItem,
  },
  props: {
    currentStage: {
      type: Object,
      required: true,
    },
    medians: {
      type: Object,
      required: true,
    },
    stages: {
      type: Array,
      required: true,
    },
    isCreatingCustomStage: {
      type: Boolean,
      required: true,
    },
    customStageFormActive: {
      type: Boolean,
      required: true,
    },
    canEditStages: {
      type: Boolean,
      required: true,
    },
    customOrdering: {
      type: Boolean,
      required: false,
      default: false,
    },
    errorSavingStageOrder: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    allowCustomOrdering() {
      return this.customOrdering && !this.errorSavingStageOrder;
    },
    manualOrderingClass() {
      return this.allowCustomOrdering ? 'js-manual-ordering' : null;
    },
  },
  mounted() {
    if (this.allowCustomOrdering) {
      const options = Object.assign({}, sortableDefaultOptions(), {
        onUpdate: event => {
          const el = event.item;

          const { previousElementSibling, nextElementSibling } = el;

          const { id } = el.dataset;
          const moveAfterId = previousElementSibling?.dataset?.id || null;
          const moveBeforeId = nextElementSibling?.dataset?.id || null;

          this.$emit('reorderStage', { id, moveAfterId, moveBeforeId });
        },
      });
      this.sortable = Sortable.create(this.$refs.list, options);
    }
  },
  beforeDestroy() {
    if (this.sortable) this.sortable.destroy();
  },
  methods: {
    medianValue(id) {
      return this.medians[id] ? this.medians[id] : null;
    },
  },
  STAGE_ACTIONS,
  noDragClass: NO_DRAG_CLASS,
};
</script>
<template>
  <ul ref="list" :class="manualOrderingClass">
    <stage-nav-item
      v-for="stage in stages"
      :id="stage.id"
      :key="`ca-stage-title-${stage.title}`"
      :title="stage.title"
      :value="medianValue(stage.id)"
      :is-active="!isCreatingCustomStage && stage.id === currentStage.id"
      :can-edit="canEditStages"
      :is-default-stage="!stage.custom"
      @remove="$emit($options.STAGE_ACTIONS.REMOVE, stage.id)"
      @hide="$emit($options.STAGE_ACTIONS.HIDE, { id: stage.id, hidden: true })"
      @select="$emit($options.STAGE_ACTIONS.SELECT, stage)"
      @edit="$emit($options.STAGE_ACTIONS.EDIT, stage)"
    />
    <add-stage-button
      v-if="canEditStages"
      :class="$options.noDragClass"
      :active="customStageFormActive"
      @showform="$emit('showAddStageForm')"
    />
  </ul>
</template>
