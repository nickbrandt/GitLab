<script>
import { GlButton, GlIcon, GlTooltip } from '@gitlab/ui';
import { approximateDuration } from '~/lib/utils/datetime_utility';
import StageCardListItem from './stage_card_list_item.vue';

export default {
  name: 'StageNavItem',
  components: {
    StageCardListItem,
    GlIcon,
    GlButton,
    GlTooltip,
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
      isTitleOverflowing: false,
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
    menuOpen() {
      return this.canEdit && this.isHover;
    },
    openMenuClasses() {
      return this.menuOpen ? 'd-flex justify-content-end' : '';
    },
  },
  mounted() {
    this.checkIfTitleOverflows();
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
    checkIfTitleOverflows() {
      const [titleEl] = this.$refs.title?.children;
      if (titleEl) {
        this.isTitleOverflowing = titleEl.scrollWidth > this.$refs.title.offsetWidth;
      }
    },
  },
};
</script>

<template>
  <li @click="handleSelectStage" @mouseover="handleHover(true)" @mouseleave="handleHover()">
    <stage-card-list-item
      :is-active="isActive"
      :can-edit="editable"
      class="d-flex justify-space-between"
    >
      <div
        ref="title"
        class="stage-nav-item-cell stage-name text-truncate w-50 pr-2"
        :class="{ 'font-weight-bold': isActive }"
      >
        <gl-tooltip v-if="isTitleOverflowing" :target="() => $refs.titleSpan">
          {{ title }}
        </gl-tooltip>
        <span ref="titleSpan">{{ title }}</span>
      </div>
      <div class="stage-nav-item-cell w-50 d-flex justify-content-between">
        <div ref="median" class="stage-median w-75 align-items-start">
          <span v-if="hasValue">{{ median }}</span>
          <span v-else class="stage-empty">{{ __('Not enough data') }}</span>
        </div>
        <div v-show="menuOpen" ref="dropdown" :class="[openMenuClasses]" class="dropdown w-25">
          <gl-button
            :title="__('More actions')"
            class="more-actions-toggle btn btn-transparent p-0"
            data-toggle="dropdown"
          >
            <gl-icon class="icon" name="ellipsis_v" />
          </gl-button>
          <ul class="more-actions-dropdown dropdown-menu dropdown-open-left">
            <template v-if="isDefaultStage">
              <li>
                <gl-button @click="handleDropdownAction('hide', $event)">
                  {{ __('Hide stage') }}
                </gl-button>
              </li>
            </template>
            <template v-else>
              <li>
                <gl-button @click="handleDropdownAction('edit', $event)">
                  {{ __('Edit stage') }}
                </gl-button>
              </li>
              <li>
                <gl-button @click="handleDropdownAction('remove', $event)">
                  {{ __('Remove stage') }}
                </gl-button>
              </li>
            </template>
          </ul>
        </div>
      </div>
    </stage-card-list-item>
  </li>
</template>
