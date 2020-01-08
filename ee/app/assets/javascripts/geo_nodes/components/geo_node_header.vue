<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import icon from '~/vue_shared/components/icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';

export default {
  components: {
    icon,
    GlLoadingIcon,
  },
  directives: {
    tooltip,
  },
  props: {
    node: {
      type: Object,
      required: true,
    },
    nodeDetails: {
      type: Object,
      required: true,
    },
    nodeDetailsLoading: {
      type: Boolean,
      required: true,
    },
    nodeDetailsFailed: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    isNodeHTTP() {
      return this.node.url.startsWith('http://');
    },
    showNodeStatusIcon() {
      if (this.nodeDetailsLoading) {
        return false;
      }

      return this.isNodeHTTP || this.nodeDetailsFailed;
    },
    nodeStatusIconClass() {
      return [
        'ml-2',
        { 'text-danger-500': this.nodeDetailsFailed, 'text-warning-500': !this.nodeDetailsFailed },
      ];
    },
    nodeStatusIconName() {
      if (this.nodeDetailsFailed) {
        return 'status_failed_borderless';
      }
      return 'warning';
    },
    nodeStatusIconTooltip() {
      if (this.nodeDetailsFailed) {
        return '';
      }
      return s__(
        'GeoNodes|You have configured Geo nodes using an insecure HTTP connection. We recommend the use of HTTPS.',
      );
    },
  },
};
</script>

<template>
  <div class="card-header">
    <div class="row">
      <div class="col-md-8 clearfix">
        <span class="d-flex align-items-center float-left append-right-10">
          <strong>{{ node.name }}</strong>
          <gl-loading-icon
            v-if="nodeDetailsLoading || node.nodeActionActive"
            class="node-details-loading prepend-left-10 inline"
          />
          <icon
            v-if="showNodeStatusIcon"
            v-tooltip
            :name="nodeStatusIconName"
            :size="18"
            :class="nodeStatusIconClass"
            :title="nodeStatusIconTooltip"
            data-container="body"
            data-placement="bottom"
          />
        </span>
        <span class="inline">
          <span
            v-if="node.current"
            class="rounded-pill gl-font-size-12 p-1 text-white bg-success-400"
          >
            {{ s__('Current node') }}
          </span>
          <span
            v-if="node.primary"
            class="ml-1 rounded-pill gl-font-size-12 p-1 text-white bg-primary-600"
          >
            {{ s__('Primary') }}
          </span>
        </span>
      </div>
    </div>
  </div>
</template>
