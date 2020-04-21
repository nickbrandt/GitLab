<script>
import { GlLoadingIcon } from '@gitlab/ui';
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
    nodeDetailsLoading: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    isNodeHTTP() {
      return this.node.url.startsWith('http://');
    },
    showNodeWarningIcon() {
      return !this.nodeDetailsLoading && this.isNodeHTTP;
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
            v-if="showNodeWarningIcon"
            v-tooltip
            class="ml-2 text-warning-500"
            name="warning"
            :size="18"
            :title="
              s__(
                'GeoNodes|You have configured Geo nodes using an insecure HTTP connection. We recommend the use of HTTPS.',
              )
            "
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
