<script>
import { GlButton } from '@gitlab/ui';
import { approximateDuration } from '~/lib/utils/datetime_utility';
import Icon from '~/vue_shared/components/icon.vue';
import StageCardListItem from './stage_card_list_item.vue';

export default {
  name: 'StageNavItem',
  components: {
    StageCardListItem,
    Icon,
    GlButton,
  },
  props: {
    isDefaultStage: {
      type: Boolean,
      default: false,
      required: false,
    },
    isActive: {
      type: Boolean,
      default: false,
      required: false,
    },
    title: {
      type: String,
      required: true,
    },
    value: {
      type: Number,
      default: 0,
      required: false,
    },
    canEdit: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  data() {
    return {
      isHover: false,
    };
  },
  computed: {
    hasValue() {
      return this.value;
    },
    median() {
      return approximateDuration(this.value);
    },
    editable() {
      return this.canEdit;
    },
  },
  methods: {
    handleDropdownAction(action) {
      this.$emit(action);
    },
    handleSelectStage(e) {
      // we don't want to emit the select event when we click the more actions dropdown
      // But we should still trigger the event if we click anywhere else in the list item
      if (this.$refs.dropdown && !this.$refs.dropdown.contains(e.target)) {
        this.$emit('select');
      }
    },
    handleHover(hoverState = false) {
      this.isHover = hoverState;
    },
  },
};
</script>

<template>
  <li @click="handleSelectStage" @mouseover="handleHover(true)" @mouseleave="handleHover()">
    <stage-card-list-item :is-active="isActive" :can-edit="editable">
      <div class="stage-nav-item-cell stage-name p-0" :class="{ 'font-weight-bold': isActive }">
        {{ title }}
      </div>
      <div class="stage-nav-item-cell stage-median mr-4">
        <span v-if="hasValue">{{ median }}</span>
        <span v-else class="stage-empty">{{ __('Not enough data') }}</span>
      </div>
      <div v-show="canEdit && isHover" ref="dropdown" class="dropdown">
        <gl-button
          :title="__('More actions')"
          class="more-actions-toggle btn btn-transparent p-0"
          data-toggle="dropdown"
        >
          <icon class="icon" name="ellipsis_v" />
        </gl-button>
        <ul class="more-actions-dropdown dropdown-menu dropdown-open-left">
          <template v-if="isDefaultStage">
            <li>
              <button
                type="button"
                class="btn-default btn-transparent"
                @click="handleDropdownAction('hide', $event)"
              >
                {{ __('Hide stage') }}
              </button>
            </li>
          </template>
          <template v-else>
            <li>
              <button
                type="button"
                class="btn-default btn-transparent"
                @click="handleDropdownAction('edit', $event)"
              >
                {{ __('Edit stage') }}
              </button>
            </li>
            <li>
              <button
                type="button"
                class="btn-danger danger"
                @click="handleDropdownAction('remove', $event)"
              >
                {{ __('Remove stage') }}
              </button>
            </li>
          </template>
        </ul>
      </div>
    </stage-card-list-item>
  </li>
</template>
