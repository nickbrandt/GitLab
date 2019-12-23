<script>
import { GlLoadingIcon, GlModal } from '@gitlab/ui';
import ciHeader from '../../vue_shared/components/header_ci_component.vue';
import eventHub from '../event_hub';
import { __ } from '~/locale';

export default {
  name: 'PipelineHeaderSection',
  components: {
    ciHeader,
    GlLoadingIcon,
    GlModal,
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      actions: this.getActions(),
    };
  },

  computed: {
    status() {
      return this.pipeline.details && this.pipeline.details.status;
    },
    shouldRenderContent() {
      return !this.isLoading && Object.keys(this.pipeline).length;
    },
  },

  watch: {
    pipeline() {
      this.actions = this.getActions();
    },
  },

  methods: {
    postAction(action) {
      const index = this.actions.indexOf(action);

      this.$set(this.actions[index], 'isLoading', true);

      eventHub.$emit('headerPostAction', action);
    },
    deletePipeline() {
      const index = this.actions.findIndex(action => action.modal === 'pipeline-delete-modal');

      this.$set(this.actions[index], 'isLoading', true);

      eventHub.$emit('headerDeleteAction', this.actions[index]);
    },

    getActions() {
      const actions = [];

      if (this.pipeline.retry_path) {
        actions.push({
          label: __('Retry'),
          path: this.pipeline.retry_path,
          cssClass: 'js-retry-button btn btn-inverted-secondary',
          type: 'button',
          isLoading: false,
        });
      }

      if (this.pipeline.cancel_path) {
        actions.push({
          label: __('Cancel running'),
          path: this.pipeline.cancel_path,
          cssClass: 'js-btn-cancel-pipeline btn btn-danger',
          type: 'button',
          isLoading: false,
        });
      }

      if (this.pipeline.delete_path) {
        actions.push({
          label: __('Delete'),
          path: this.pipeline.delete_path,
          modal: 'pipeline-delete-modal',
          cssClass: 'js-btn-delete-pipeline btn btn-danger btn-inverted',
          type: 'modal-button',
          isLoading: false,
        });
      }

      return actions;
    },
  },
};
</script>
<template>
  <div class="pipeline-header-container">
    <ci-header
      v-if="shouldRenderContent"
      :status="status"
      :item-id="pipeline.id"
      :time="pipeline.created_at"
      :user="pipeline.user"
      :actions="actions"
      item-name="Pipeline"
      @actionClicked="postAction"
    />

    <gl-loading-icon v-if="isLoading" :size="2" class="prepend-top-default append-bottom-default" />

    <gl-modal
      modal-id="pipeline-delete-modal"
      :title="__('Delete pipeline')"
      :ok-title="__('Delete pipeline')"
      ok-variant="danger"
      @ok="deletePipeline()"
    >
      <p>
        {{
          __(
            'Are you sure you want to delete this pipeline? Doing so will expire all pipeline caches and delete all related objects, such as builds, logs, artifacts, and triggers. This action cannot be undone.',
          )
        }}
      </p>
    </gl-modal>
  </div>
</template>
