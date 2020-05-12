<script>
import { GlButton, GlFormInput } from '@gitlab/ui';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import { timeRanges } from '~/vue_shared/constants';
import createIteration from '../queries/create_iteration.mutation.graphql';
import DueDateSelectors from '~/due_date_select';

export default {
  timeRanges,
  components: {
    GlButton,
    GlFormInput,
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
  data() {
    return {
      iterations: [],
      loading: 0,
      title: 'test',
      description: 'test desc',
      startDate: '2020-05-02',
      dueDate: '2020-05-10',
    };
  },
  mounted() {
    new DueDateSelectors();
  },
  methods: {
    save() {
      this.$apollo.mutate({
        mutation: createIteration,
        variables: {
          input: {
            groupPath: this.groupPath,
            title: this.title,
            description: this.description,
            startDate: this.startDate,
            dueDate: this.dueDate,
          },
        },
      }).then(({ data, error }) => {
        console.log(data, error)
      }).catch(e => {
        console.log(e)
      })
    },
    cancel() {
      console.log('TODO');
    }
  }
};
</script>

<template>
  <div>
    <div class="d-flex">
      <h3 class="page-title">{{ __('New Iteration') }}</h3>
    </div>
    <hr />
    <section class="row common-note-form">
      <div class="col-sm-6">
        <div class="form-group row">
          <div class="col-form-label col-sm-2">
            <label for="iteration-title">{{ __('Title') }}</label>
          </div>
          <div class="col-sm-10">
            <gl-form-input id="iteration-title" v-model="title" autocomplete="off" />
          </div>
        </div>

        <div class="form-group row">
          <div class="col-form-label col-sm-2">
            <label for="description">{{ __('Description') }}</label>
          </div>
          <div class="col-sm-10">
            <markdown-field
              :markdown-preview-path="previewMarkdownPath"
              :can-attach-file="false"
              :enable-autocomplete="true"
              label="Description"
              :textarea-value="description"
              markdown-docs-path="/help/user/markdown"
              :add-spacing-classes="false"
              class="md-area"
            >
              <textarea
                id="description"
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
            <gl-form-input
              id="milestone_start_date"
              v-model="startDate"
              class="datepicker form-control"
              :placeholder="__('Select start date')"
              autocomplete="off"
              name="milestone[start_date]"
            />
            <a class="inline float-right gl-mt-2 js-clear-start-date" href="#">{{ __('Clear start date') }}</a
            >
          </div>
        </div>
        <div class="form-group row">
          <div class="col-form-label col-sm-2">
            <label for="milestone_due_date">{{ __('Due Date') }}</label>
          </div>
          <div class="col-sm-10">
            <gl-form-input
              id="milestone_due_date"
              v-model="dueDate"
              class="datepicker form-control"
              :placeholder="__('Select due date')"
              autocomplete="off"
              type="text"
              name="milestone[due_date]"
            />
            <a class="inline float-right gl-mt-2 js-clear-due-date" href="#">{{ __('Clear due date') }}</a>
          </div>
        </div>
      </div>
    </section>
    
    <div class="form-actions d-flex">
      <gl-button variant="success" @click="save">{{ __('Save') }}</gl-button>
      <gl-button class="ml-auto" @click="cancel">{{ __('Cancel') }}</gl-button>
    </div>
  </div>
</template>
