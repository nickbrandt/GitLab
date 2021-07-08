<script>
  import { GlIcon, GlDatepicker, GlTooltipDirective, GlLink, GlPopover } from '@gitlab/ui';
  import createFlash from '~/flash';
  import { IssuableType } from '~/issue_show/constants';
  import { dateInWords, formatDate, parsePikadayDate } from '~/lib/utils/datetime_utility';
  import { s__, __, sprintf } from '~/locale';
  import SidebarEditableItem from '~/sidebar/components/sidebar_editable_item.vue';
  import { dateFields, dateTypes, dueDateQueries, startDateQueries } from '~/sidebar/constants';

  export default {
    i18n: {
      title: s__('EscalationPolicies|Escalation policy'),

  },
    tracking: {
      event: 'click_edit_button',
      label: 'right_sidebar',
    },
    directives: {
      GlTooltip: GlTooltipDirective,
    },
    components: {
      GlIcon,
      GlDatepicker,
      GlLink,
      GlPopover,
      SidebarEditableItem,
    },
    inject: ['canUpdate'],
    props: {
      iid: {
        type: String,
        required: true,
      },
      fullPath: {
        type: String,
        required: true,
      },
      dateType: {
        type: String,
        required: false,
        default: dateTypes.due,
      },
      issuableType: {
        required: true,
        type: String,
      },
      canInherit: {
        required: false,
        type: Boolean,
        default: false,
      },
    },
    data() {
      return {
        issuable: {},
        loading: false,

      };
    },
    apollo: {
      // issuable: {
      //   query() {
      //     return this.dateQueries[this.issuableType].query;
      //   },
      //   variables() {
      //     return {
      //       fullPath: this.fullPath,
      //       iid: String(this.iid),
      //     };
      //   },
      //   update(data) {
      //     return data.workspace?.issuable || {};
      //   },
      //   result({ data }) {
      //     this.$emit(`${this.dateType}Updated`, data.workspace?.issuable?.[this.dateType]);
      //   },
      //   error() {
      //     createFlash({
      //       message: sprintf(
      //         __('Something went wrong while setting %{issuableType} %{dateType} date.'),
      //         {
      //           issuableType: this.issuableType,
      //           dateType: this.dateType === dateTypes.start ? 'start' : 'due',
      //         },
      //       ),
      //     });
      //   },
      // },
    },
    computed: {

    },
    methods: {

    },
    i18n: {
      dueDate: __('Due date'),
      startDate: __('Start date'),
      noDate: __('None'),
      removeDueDate: __('remove due date'),
      removeStartDate: __('remove start date'),
      dateHelpValidMessage: __(
        'These dates affect how your epics appear in the roadmap. Set a fixed date or one inherited from the milestones assigned to issues in this epic.',
      ),
      help: __('Help'),
      learnMore: __('Learn more'),
    },
    dateHelpUrl: '/help/user/group/epics/index.md#start-date-and-due-date',
  };
</script>

<template>
  <sidebar-editable-item
    ref="editable"
    :title="$options.i18n.title"
    :tracking="tracking"
    :loading="isLoading"
    class="block"
    @open=""
  >
    <template v-if="canInherit" #title-extra>
<!--      <gl-icon-->
<!--        ref="epicDatePopover"-->
<!--        name="question-o"-->
<!--        class="gl-ml-3 gl-cursor-pointer gl-text-blue-600 hide-collapsed"-->
<!--        tabindex="0"-->
<!--        :aria-label="$options.i18n.help"-->
<!--        data-testid="inherit-date-popover"-->
<!--      />-->
<!--      <gl-popover :target="epicDatePopoverEl" triggers="focus" placement="left" boundary="viewport">-->
<!--        <p>{{ $options.i18n.dateHelpValidMessage }}</p>-->
<!--        <gl-link :href="$options.dateHelpUrl" target="_blank">{{-->
<!--          $options.i18n.learnMore-->
<!--          }}</gl-link>-->
<!--      </gl-popover>-->
      caninherit
    </template>
    <template #collapsed>
  collapsed stated here
    </template>
    <template #default>
<!--      <gl-datepicker-->
<!--        v-if="!isLoading"-->
<!--        ref="datePicker"-->
<!--        class="gl-relative"-->
<!--        :default-date="parsedDate"-->
<!--        :first-day="firstDay"-->
<!--        show-clear-button-->
<!--        autocomplete="off"-->
<!--        @input="setDate"-->
<!--        @clear="setDate(null)"-->
<!--      />-->
      default state here
    </template>
  </sidebar-editable-item>
</template>
