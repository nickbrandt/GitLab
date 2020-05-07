<script>
import { GlButton, GlLink } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlLink,
  },
  data() {
    return {
      canEdit: true, // TODO: prop
      iterationSelected: false, // TODO: probably computed based on selected item?
      iteration: {
        name: 'Iteration 2',
        url: 'https://gitlab.com/iterations/3',
      },
    }
  }
}

// .sidebar-collapsed-icon.has-tooltip{ title: sidebar_milestone_tooltip_label(milestone), data: { container: 'body', html: 'true', placement: 'left', boundary: 'viewport' } }
//             = icon('clock-o', 'aria-hidden': 'true')
//             %span.milestone-title.collapse-truncated-title
//               - if milestone.present?
//                 = milestone[:title]
//               - else
//                 = _('None')
//           .title.hide-collapsed

//             = icon('spinner spin', class: 'hidden block-loading', 'aria-hidden': 'true')
//             - if can_edit_issuable
//               = link_to _('Edit'), '#', class: 'js-sidebar-dropdown-toggle edit-link float-right', 
//           .value.hide-collapsed
//             - if milestone.present?
//               = link_to milestone[:title], milestone[:web_url], class: "bold has-tooltip", title: sidebar_milestone_remaining_days(milestone), data: { container: "body", html: 'true', boundary: 'viewport', qa_selector: 'milestone_link', qa_title: milestone[:title] }

//           .selectbox.hide-collapsed
//             = f.hidden_field 'milestone_id', value: milestone[:id], id: nil
//             = dropdown_tag('Milestone', options: { title: _('Assign milestone'), toggle_class: 'js-milestone-select js-extra-options', filter: true, dropdown_class: 'dropdown-menu-selectable', placeholder: _('Search milestones'), data: { show_no: true, field_name: "#{issuable_type}[milestone_id]", project_id: issuable_sidebar[:project_id], issuable_id: issuable_sidebar[:id], milestones: issuable_sidebar[:project_milestones_path], ability_name: issuable_type, issue_update: issuable_sidebar[:issuable_json_path], use_id: true, default_no: true, selected: milestone[:title], null_default: true, display: 'static' }})
</script>

<template>
  <div class="mt-3">
    <div class="sidebar-collapsed-icon" b-gl-tooltip=""></div>
    <div class="title hide-collapsed">
      {{ __('Iteration') }}
      <gl-button v-if="canEdit" class="js-sidebar-dropdown-toggle edit-link float-right"
        data-track-label="right_sidebar" data-track-property="iteration" data-track-event="click_edit_button"
      >{{ __('Edit') }}</gl-button>
    </div>
    <div class="value hide-collapsed">
      <gl-link v-if="iterationSelected" href="">Second Iteration</gl-link>
      <span v-else class="no-value">{{ __('None') }}</span>
    </div>
  </div>
</template>

