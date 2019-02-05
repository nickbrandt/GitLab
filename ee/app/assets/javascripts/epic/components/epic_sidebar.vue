<script>
import { mapState, mapGetters, mapActions } from 'vuex';

import SidebarParentEpic from 'ee/sidebar/components/sidebar_item_epic.vue';

import epicUtils from '../utils/epic_utils';

import SidebarHeader from './sidebar_items/sidebar_header.vue';
import SidebarTodo from './sidebar_items/sidebar_todo.vue';
import SidebarDatePicker from './sidebar_items/sidebar_date_picker.vue';
import SidebarDatePickerCollapsed from '~/vue_shared/components/sidebar/collapsed_grouped_date_picker.vue';
import SidebarLabels from './sidebar_items/sidebar_labels.vue';
import SidebarParticipants from '~/sidebar/components/participants/participants.vue';
import SidebarSubscription from './sidebar_items/sidebar_subscription.vue';

import { dateTypes } from '../constants';

export default {
  dateTypes,
  components: {
    SidebarHeader,
    SidebarTodo,
    SidebarDatePicker,
    SidebarDatePickerCollapsed,
    SidebarLabels,
    SidebarParentEpic,
    SidebarParticipants,
    SidebarSubscription,
  },
  computed: {
    ...mapState([
      'canUpdate',
      'sidebarCollapsed',
      'participants',
      'startDateSourcingMilestoneTitle',
      'startDateSourcingMilestoneDates',
      'startDateIsFixed',
      'startDateFixed',
      'startDateFromMilestones',
      'dueDateSourcingMilestoneTitle',
      'dueDateSourcingMilestoneDates',
      'dueDateIsFixed',
      'dueDateFixed',
      'dueDateFromMilestones',
      'epicStartDateSaveInProgress',
      'epicDueDateSaveInProgress',
    ]),
    ...mapGetters([
      'isUserSignedIn',
      'isDateInvalid',
      'startDateTimeFixed',
      'startDateTimeFromMilestones',
      'startDateTime',
      'startDateForCollapsedSidebar',
      'dueDateTimeFixed',
      'dueDateTimeFromMilestones',
      'dueDateTime',
      'dueDateForCollapsedSidebar',
      'parentEpic',
    ]),
  },
  mounted() {
    this.toggleSidebarFlag(epicUtils.getCollapsedGutter());
  },
  methods: {
    ...mapActions([
      'toggleSidebar',
      'toggleSidebarFlag',
      'toggleStartDateType',
      'toggleDueDateType',
      'saveDate',
    ]),
    getDateFromMilestonesTooltip(dateType) {
      return epicUtils.getDateFromMilestonesTooltip({
        dateType,
        startDateSourcingMilestoneTitle: this.startDateSourcingMilestoneTitle,
        startDateSourcingMilestoneDates: this.startDateSourcingMilestoneDates,
        startDateTimeFromMilestones: this.startDateTimeFromMilestones,
        dueDateSourcingMilestoneTitle: this.dueDateSourcingMilestoneTitle,
        dueDateSourcingMilestoneDates: this.dueDateSourcingMilestoneDates,
        dueDateTimeFromMilestones: this.dueDateTimeFromMilestones,
      });
    },
    changeStartDateType(dateTypeIsFixed, typeChangeOnEdit) {
      this.toggleStartDateType({ dateTypeIsFixed });
      if (!typeChangeOnEdit) {
        this.saveDate({
          newDate: dateTypeIsFixed ? this.startDateFixed : this.startDateFromMilestones,
          dateType: dateTypes.start,
          dateTypeIsFixed,
        });
      }
    },
    saveStartDate(date) {
      this.saveDate({
        dateType: dateTypes.start,
        newDate: date,
        dateTypeIsFixed: true,
      });
    },
    changeDueDateType(dateTypeIsFixed, typeChangeOnEdit) {
      this.toggleDueDateType({ dateTypeIsFixed });
      if (!typeChangeOnEdit) {
        this.saveDate({
          newDate: dateTypeIsFixed ? this.dueDateFixed : this.dueDateFromMilestones,
          dateType: dateTypes.due,
          dateTypeIsFixed,
        });
      }
    },
    saveDueDate(date) {
      this.saveDate({
        dateType: dateTypes.due,
        newDate: date,
        dateTypeIsFixed: true,
      });
    },
  },
};
</script>

<template>
  <aside
    :class="{
      'right-sidebar-expanded': !sidebarCollapsed,
      'right-sidebar-collapsed': sidebarCollapsed,
    }"
    :data-signed-in="isUserSignedIn"
    class="right-sidebar epic-sidebar"
  >
    <div class="issuable-sidebar js-issuable-update">
      <sidebar-header :sidebar-collapsed="sidebarCollapsed" />
      <sidebar-todo
        v-show="sidebarCollapsed && isUserSignedIn"
        :sidebar-collapsed="sidebarCollapsed"
      />
      <sidebar-date-picker
        v-show="!sidebarCollapsed"
        :can-update="canUpdate"
        :sidebar-collapsed="sidebarCollapsed"
        :show-toggle-sidebar="!isUserSignedIn"
        :label="__('Start date')"
        :date-picker-label="__('Fixed start date')"
        :date-invalid-tooltip="
          __('This date is after the due date, so this epic won\'t appear in the roadmap.')
        "
        :date-from-milestones-tooltip="getDateFromMilestonesTooltip($options.dateTypes.start)"
        :date-save-in-progress="epicStartDateSaveInProgress"
        :selected-date-is-fixed="startDateIsFixed"
        :date-fixed="startDateTimeFixed"
        :date-from-milestones="startDateTimeFromMilestones"
        :selected-date="startDateTime"
        :is-date-invalid="isDateInvalid"
        block-class="start-date"
        @toggleCollapse="toggleSidebar({ sidebarCollapsed })"
        @toggleDateType="changeStartDateType"
        @saveDate="saveStartDate"
      />
      <sidebar-date-picker
        v-show="!sidebarCollapsed"
        :can-update="canUpdate"
        :sidebar-collapsed="sidebarCollapsed"
        :label="__('Due date')"
        :date-picker-label="__('Fixed due date')"
        :date-invalid-tooltip="
          __('This date is before the start date, so this epic won\'t appear in the roadmap.')
        "
        :date-from-milestones-tooltip="getDateFromMilestonesTooltip($options.dateTypes.due)"
        :date-save-in-progress="epicDueDateSaveInProgress"
        :selected-date-is-fixed="dueDateIsFixed"
        :date-fixed="dueDateTimeFixed"
        :date-from-milestones="dueDateTimeFromMilestones"
        :selected-date="dueDateTime"
        :is-date-invalid="isDateInvalid"
        block-class="due-date"
        @toggleDateType="changeDueDateType"
        @saveDate="saveDueDate"
      />
      <sidebar-date-picker-collapsed
        v-show="sidebarCollapsed"
        :collapsed="sidebarCollapsed"
        :min-date="startDateForCollapsedSidebar"
        :max-date="dueDateForCollapsedSidebar"
        @toggleCollapse="toggleSidebar({ sidebarCollapsed })"
      />
      <sidebar-labels :can-update="canUpdate" :sidebar-collapsed="sidebarCollapsed" />
      <div class="block parent-epic">
        <sidebar-parent-epic :block-title="__('Parent epic')" :initial-epic="parentEpic" />
      </div>
      <div class="block participants">
        <sidebar-participants
          :participants="participants"
          @toggleSidebar="toggleSidebar({ sidebarCollapsed })"
        />
      </div>
      <sidebar-subscription :sidebar-collapsed="sidebarCollapsed" />
    </div>
  </aside>
</template>
