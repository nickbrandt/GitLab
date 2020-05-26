<script>
import { GlButton, GlDatepicker, GlForm, GlFormCheckbox, GlFormInput } from '@gitlab/ui';
import createFlash from '~/flash';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import createEpic from '../queries/createEpic.mutation.graphql';

export default {
  components: {
    GlButton,
    GlDatepicker,
    GlForm,
    GlFormCheckbox,
    GlFormInput,
    MarkdownField,
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
    groupEpicsPath: {
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
      labelIds: [],
      confidential: false,
      description: '',
      title: '',
      dueDateFixed: null,
      startDateFixed: null,
      loading: false,
    };
  },
  methods: {
    save() {
      this.loading = true;

      this.$apollo
        .mutate({
          mutation: createEpic,
          variables: {
            input: {
              addLabelIds: this.labels,
              groupPath: this.groupPath,
              title: this.title,
              description: this.description,
              confidential: this.confidential,
              startDateFixed: this.startDateFixed,
              startDateIsFixed: Boolean(this.startDateFixed),
              dueDateFixed: this.dueDateFixed,
              dueDateIsFixed: Boolean(this.dueDateFixed),
            },
          },
        })
        .then(({ data }) => {
          const { errors, epic } = data.createEpic;
          if (errors?.length > 0) {
            createFlash(errors[0]);
            return;
          }

          visitUrl(epic.webUrl);
        })
        .catch(() => {
          createFlash(__('Unable to save epic. Please try again'));
        })
        .finally(() => {
          this.loading = false;
        });
    },
    updateDueDate(val) {
      this.dueDateFixed = val;
    },
    updateStartDate(val) {
      this.startDateFixed = val;
    },
  },
};
</script>

<template>
  <div>
    <h3 class="page-title">{{ __('New Epic') }}</h3>
    <hr />
    <gl-form class="common-note-form">
      <div class="form-group row">
        <div class="col-form-label col-sm-2">
          <label for="epic-title">{{ __('Title') }}</label>
        </div>
        <div class="col-sm-8">
          <gl-form-input
            id="epic-title"
            v-model="title"
            :placeholder="__('Title')"
            autocomplete="off"
            autofocus
          />
        </div>
      </div>

      <div class="form-group row">
        <div class="col-form-label col-sm-2">
          <label for="epic-description">{{ __('Description') }}</label>
        </div>
        <div class="col-sm-10">
          <markdown-field
            :markdown-preview-path="previewMarkdownPath"
            :enable-autocomplete="true"
            label="Description"
            :textarea-value="description"
            markdown-docs-path="/help/user/markdown"
            quick-actions-docs-path="/help/user/project/quick_actions"
            :add-spacing-classes="false"
            class="md-area"
          >
            <template #textarea>
              <textarea
                id="epic-description"
                v-model="description"
                class="note-textarea js-gfm-input js-autosize markdown-area"
                dir="auto"
                data-supports-quick-actions="true"
                :placeholder="__('Write a comment or drag your files here…')"
                :aria-label="__('Description')"
              >
              </textarea>
            </template>
          </markdown-field>
        </div>
      </div>

      <div class="form-group row">
        <div class="col-sm-10 offset-sm-2">
          <gl-form-checkbox v-model="confidential">{{
            __(
              'This epic and any containing child epics are confidential and should only be visible to team members with at least Reporter access.',
            )
          }}</gl-form-checkbox>
        </div>
      </div>
      <hr />
      <div class="row">
        <div class="col-md-6">
          <div class="form-group row">
            <div class="col-form-label col-md-2 col-lg-4">
              <label for="epic-title">{{ __('Labels') }}</label>
            </div>
            <div class="col-md-8 col-sm-10"></div>
          </div>
        </div>
        <div class="col-md-6">
          <div class="form-group row">
            <div class="col-form-label col-md-2 col-lg-4">
              <label for="epic-start-date">{{ __('Start date') }}</label>
            </div>
            <div class="col-md-8 col-sm-10">
              <div class="issuable-form-select-holder gl-mr-2">
                <gl-datepicker v-model="startDateFixed" />
              </div>
              <a
                v-show="startDateFixed"
                class="gl-white-space-nowrap js-clear-start-date"
                href="#"
                @click="updateStartDate(null)"
                >{{ __('Clear start date') }}</a
              >
              <span class="block gl-text-gray-400">{{
                __('An empty date will inherit from milestone dates')
              }}</span>
            </div>
          </div>
          <div class="form-group row">
            <div class="col-form-label col-md-2 col-lg-4">
              <label for="epic-due-date">{{ __('Due Date') }}</label>
            </div>
            <div class="col-md-8 col-sm-10">
              <div class="issuable-form-select-holder gl-mr-2">
                <gl-datepicker v-model="dueDateFixed" />
              </div>
              <a
                v-show="dueDateFixed"
                class="gl-white-space-nowrap js-clear-due-date"
                href="#"
                @click="updateDueDate(null)"
                >{{ __('Clear due date') }}</a
              >
              <span class="block gl-text-gray-400">{{
                __('An empty date will inherit from milestone dates')
              }}</span>
            </div>
          </div>
        </div>
      </div>
    </gl-form>

    <div class="form-actions gl-display-flex">
      <gl-button :loading="loading" data-testid="save-epic" variant="success" @click="save">
        {{ __('Create epic') }}
      </gl-button>
      <gl-button class="ml-auto" data-testid="cancel-epic" :href="groupEpicsPath">{{
        __('Cancel')
      }}</gl-button>
    </div>
  </div>
</template>
