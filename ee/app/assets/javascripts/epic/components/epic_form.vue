<script>
import { GlButton, GlDatepicker, GlForm, GlFormCheckbox, GlFormInput } from '@gitlab/ui';
import { visitUrl, joinPaths } from '~/lib/utils/url_utility';
import createFlash from '~/flash';
import { __ } from '~/locale';
import LabelsSelectVue from '~/vue_shared/components/sidebar/labels_select_vue/labels_select_root.vue';
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
    LabelsSelectVue,
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
    markdownPreviewPath: {
      type: String,
      required: false,
      default: '',
    },
    markdownDocsPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      title: '',
      description: '',
      confidential: false,
      labels: [],
      startDateFixed: null,
      dueDateFixed: null,
      loading: false,
    };
  },
  computed: {
    labelIds() {
      return this.labels.map(label => label.id);
    },
  },
  methods: {
    groupUrl(path) {
      return joinPaths('/groups', this.groupPath, '/-/', path);
    },
    save() {
      this.loading = true;

      return this.$apollo
        .mutate({
          mutation: createEpic,
          variables: {
            input: {
              addLabelIds: this.labelIds,
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
    handleUpdateSelectedLabels(labels) {
      const ids = [];
      const allLabels = [...labels, ...this.labels];

      this.labels = allLabels.filter(label => {
        const exists = ids.includes(label.id);
        ids.push(label.id);

        return !exists && label.set;
      });
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
        <div class="col-sm-10">
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
            :markdown-preview-path="markdownPreviewPath"
            :markdown-docs-path="markdownDocsPath"
            :can-suggest="false"
            :can-attach-file="true"
            :enable-autocomplete="true"
            :add-spacing-classes="false"
            :textarea-value="description"
            :label="__('Description')"
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
      <div class="form-group row gl-mt-7">
        <div class="col-sm-10 offset-sm-2">
          <gl-form-checkbox v-model="confidential" data-testid="epic-confidentiality">{{
            __(
              'This epic and any containing child epics are confidential and should only be visible to team members with at least Reporter access.',
            )
          }}</gl-form-checkbox>
        </div>
      </div>
      <hr />
      <div class="row">
        <div class="col-lg-6">
          <div class="form-group row">
            <div class="col-form-label col-md-2 col-lg-4">
              <label>{{ __('Labels') }}</label>
            </div>
            <div class="col-md-8 col-sm-10">
              <div class="issuable-form-select-holder">
                <labels-select-vue
                  :allow-label-edit="false"
                  :allow-label-create="true"
                  :allow-multiselect="true"
                  :allow-scoped-labels="false"
                  :selected-labels="labels"
                  :labels-fetch-path="
                    groupUrl('labels.json?include_ancestor_groups=true&only_group_labels=true')
                  "
                  :labels-manage-path="groupUrl('labels')"
                  :labels-filter-base-path="groupUrl('epics')"
                  :labels-list-title="__('Select label')"
                  :dropdown-button-text="__('Labels')"
                  variant="embedded"
                  class="block labels js-labels-block"
                  @updateSelectedLabels="handleUpdateSelectedLabels"
                  >{{ __('None') }}</labels-select-vue
                >
              </div>
            </div>
          </div>
        </div>
        <div class="col-lg-6">
          <div class="form-group row">
            <div class="col-form-label col-md-2 col-lg-4">
              <label>{{ __('Start date') }}</label>
            </div>
            <div class="col-md-8 col-sm-10">
              <div class="issuable-form-select-holder gl-mr-2">
                <gl-datepicker v-model="startDateFixed" data-testid="epic-start-date" />
              </div>
              <a
                v-show="startDateFixed"
                class="gl-white-space-nowrap"
                data-testid="clear-start-date"
                href="#"
                @click="updateStartDate(null)"
                >{{ __('Clear start date') }}</a
              >
              <span class="block gl-line-height-normal gl-mt-3 gl-text-gray-500">{{
                __('Leave empty to inherit from milestone dates')
              }}</span>
            </div>
          </div>
          <div class="form-group row">
            <div class="col-form-label col-md-2 col-lg-4">
              <label>{{ __('Due Date') }}</label>
            </div>
            <div class="col-md-8 col-sm-10">
              <div class="issuable-form-select-holder gl-mr-2">
                <gl-datepicker v-model="dueDateFixed" data-testid="epic-due-date" />
              </div>
              <a
                v-show="dueDateFixed"
                class="gl-white-space-nowrap"
                data-testid="clear-due-date"
                href="#"
                @click="updateDueDate(null)"
                >{{ __('Clear due date') }}</a
              >
              <span class="block gl-line-height-normal gl-mt-3 gl-text-gray-500">{{
                __('Leave empty to inherit from milestone dates')
              }}</span>
            </div>
          </div>
        </div>
      </div>
    </gl-form>

    <div class="footer-block row-content-block gl-display-flex">
      <gl-button
        :loading="loading"
        data-testid="save-epic"
        variant="success"
        :disabled="!title"
        @click="save"
      >
        {{ __('Create epic') }}
      </gl-button>
      <gl-button class="gl-ml-auto" data-testid="cancel-epic" :href="groupEpicsPath">{{
        __('Cancel')
      }}</gl-button>
    </div>
  </div>
</template>
