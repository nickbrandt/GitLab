<script>
import { GlButton, GlFormGroup, GlFormInput, GlFormInputGroup } from '@gitlab/ui';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import { timeRanges } from '~/vue_shared/constants';
import DateTimePickerInput from '~/vue_shared/components/date_time_picker/date_time_picker_input.vue';
import GroupIterationQuery from '../queries/group_iteration.query.graphql';
import DueDateSelectors from '~/due_date_select';

export default {
  timeRanges,
  components: {
    DateTimePickerInput,
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlFormInputGroup,
    MarkdownField,
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
    previewMarkdownPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  // apollo: {
  //   iterations: {
  //     query: GroupIterationQuery,
  //     update: data => data.group.sprints.nodes,
  //     variables() {
  //       return {
  //         fullPath: this.groupPath,
  //         state: this.state,
  //       };
  //     },
  //   },
  // },
  data() {
    return {
      iterations: [],
      loading: 0,
      title: '',
      description: '',
      startDate: '',
      dueDate: null,
    };
  },
  mounted() {
    new DueDateSelectors();
  }
};
</script>

<template>
  <div>
    <div class="d-flex">
      <h3 class="page-title">{{ __('New Iteration') }}</h3>
      <!-- TODO: util classes. canAdminIteration -->
      <!-- <div class="milestone-buttons" v-if="true">
        <gl-button>{{ __('Edit') }}</gl-button>
        <gl-button variant="warning-outline">{{ __('Close iteration') }} </gl-button>
        <gl-button variant="danger">{{ __('Delete') }} </gl-button>
      </div> -->
    </div>
    <hr />
    <section class="row common-note-form">
      <div class="col-sm-6">
        <gl-form-group :label="__('Title')" label-for="title" label-class="label-bold">
          <div class="input-group">
            <gl-form-input id="title" :value="title" />
          </div>
        </gl-form-group>

        <div class="form-group row">
          <div class="col-form-label col-sm-2">
            <label for="issue-description">{{ __('Description') }}</label>
          </div>
          <div class="col-sm-10">
            <markdown-field
              :markdown-preview-path="previewMarkdownPath"
              :can-attach-file="false"
              :enable-autocomplete="true"
              label="Description"
              :textarea-value="description"
              markdown-docs-path="/help/user/markdown"
              class="md-area"
            >
              <textarea
                id="issue-description"
                ref="textarea"
                slot="textarea"
                v-model="description"
                class="note-textarea js-gfm-input js-autosize markdown-area"
                dir="auto"
                data-supports-quick-actions="false"
                :aria-label="__('Description')"
              >
              </textarea>
            </markdown-field>
          </div>
        </div>
      </div>

      <div class="col-md-6">
        <div class="form-group row">
          <div class="col-form-label col-sm-2">
            <label for="milestone_start_date">{{ __('Start date') }}</label>
          </div>
          <div class="col-sm-10">
            <input
              id="milestone_start_date"
              v-model="startDate"
              class="datepicker form-control"
              :placeholder="__('Select start date')"
              autocomplete="off"
              type="text"
              name="milestone[start_date]"
            />
            <a class="inline float-right prepend-top-5 js-clear-start-date" href="#">Clear start date</a
            >
          </div>
        </div>
        <div class="form-group row">
          <div class="col-form-label col-sm-2">
            <label for="milestone_due_date">{{ __('Due Date') }}</label>
          </div>
          <div class="col-sm-10">
            <input
              id="milestone_due_date"
              class="datepicker form-control"
              :placeholder="__('Select due date')"
              autocomplete="off"
              type="text"
              name="milestone[due_date]"
            />
            <a class="inline float-right prepend-top-5 js-clear-due-date" href="#">{{ __('Clear due date') }}</a>
            <div
              class="pika-single gitlab-theme animate-picker is-hidden is-bound"
              style="position: static; left: auto; top: auto;"
            ></div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>
