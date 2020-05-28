<script>
import { GlButton, GlForm, GlFormInput } from '@gitlab/ui';
import createFlash from '~/flash';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import createIteration from '../queries/create_iteration.mutation.graphql';
import DueDateSelectors from '~/due_date_select';

export default {
  components: {
    GlButton,
    GlForm,
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
    iterationsListPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      iterations: [],
      loading: false,
      title: '',
      description: '',
      startDate: '',
      dueDate: '',
    };
  },
  mounted() {
    // eslint-disable-next-line no-new
    new DueDateSelectors();
  },
  methods: {
    save() {
      this.loading = true;
      return this.$apollo
        .mutate({
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
        })
        .then(({ data }) => {
          const { errors, iteration } = data.createIteration;
          if (errors?.length > 0) {
            this.loading = false;
            createFlash(errors[0]);
            return;
          }

          visitUrl(iteration.webUrl);
        })
        .catch(() => {
          this.loading = false;
          createFlash(__('Unable to save iteration. Please try again'));
        });
    },
    updateDueDate(val) {
      this.dueDate = val;
    },
    updateStartDate(val) {
      this.startDate = val;
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-display-flex">
      <h3 class="page-title">{{ __('New Iteration') }}</h3>
    </div>
    <hr />
    <gl-form class="row common-note-form">
      <div class="col-md-6">
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
            <label for="iteration-description">{{ __('Description') }}</label>
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
              <template #textarea>
                <textarea
                  id="iteration-description"
                  v-model="description"
                  class="note-textarea js-gfm-input js-autosize markdown-area"
                  dir="auto"
                  data-supports-quick-actions="false"
                  :aria-label="__('Description')"
                >
                </textarea>
              </template>
            </markdown-field>
          </div>
        </div>
      </div>

      <div class="col-md-6">
        <div class="form-group row">
          <div class="col-form-label col-sm-2">
            <label for="iteration-start-date">{{ __('Start date') }}</label>
          </div>
          <div class="col-sm-10">
            <gl-form-input
              id="iteration-start-date"
              v-model="startDate"
              class="datepicker form-control"
              :placeholder="__('Select start date')"
              autocomplete="off"
              @change="updateStartDate"
            />
            <a class="inline float-right gl-mt-2 js-clear-start-date" href="#">{{
              __('Clear start date')
            }}</a>
          </div>
        </div>
        <div class="form-group row">
          <div class="col-form-label col-sm-2">
            <label for="iteration-due-date">{{ __('Due Date') }}</label>
          </div>
          <div class="col-sm-10">
            <gl-form-input
              id="iteration-due-date"
              v-model="dueDate"
              class="datepicker form-control"
              :placeholder="__('Select due date')"
              autocomplete="off"
              @change="updateDueDate"
            />
            <a class="inline float-right gl-mt-2 js-clear-due-date" href="#">{{
              __('Clear due date')
            }}</a>
          </div>
        </div>
      </div>
    </gl-form>

    <div class="form-actions d-flex">
      <gl-button :loading="loading" data-testid="save-iteration" variant="success" @click="save">{{
        __('Create iteration')
      }}</gl-button>
      <gl-button class="ml-auto" data-testid="cancel-iteration" :href="iterationsListPath">{{
        __('Cancel')
      }}</gl-button>
    </div>
  </div>
</template>
