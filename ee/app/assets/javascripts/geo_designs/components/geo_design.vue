<script>
import { mapActions } from 'vuex';
import { GlLink, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import { ACTION_TYPES } from '../store/constants';
import GeoDesignStatus from './geo_design_status.vue';
import GeoDesignTimeAgo from './geo_design_time_ago.vue';

export default {
  name: 'GeoDesign',
  components: {
    GlLink,
    GlButton,
    GeoDesignTimeAgo,
    GeoDesignStatus,
  },
  props: {
    name: {
      type: String,
      required: true,
    },
    projectId: {
      type: Number,
      required: true,
    },
    syncStatus: {
      type: String,
      required: false,
      default: '',
    },
    lastSynced: {
      type: String,
      required: false,
      default: '',
    },
    lastVerified: {
      type: String,
      required: false,
      default: '',
    },
    lastChecked: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      timeAgoArray: [
        {
          label: __('Last successful sync'),
          dateString: this.lastSynced,
          defaultText: __('Never'),
        },
        {
          label: __('Last time verified'),
          dateString: this.lastVerified,
          defaultText: __('Not Implemented'),
        },
        {
          label: __('Last repository check run'),
          dateString: this.lastChecked,
          defaultText: __('Not Implemented'),
        },
      ],
    };
  },
  methods: {
    ...mapActions(['initiateDesignSync']),
  },
  actionTypes: ACTION_TYPES,
};
</script>

<template>
  <div class="card">
    <div class="card-header d-flex align-center">
      <gl-link class="font-weight-bold" :href="`/${name}`" target="_blank">{{ name }}</gl-link>
      <div class="ml-auto">
        <gl-button
          @click="initiateDesignSync({ projectId, name, action: $options.actionTypes.RESYNC })"
          >{{ __('Resync') }}</gl-button
        >
      </div>
    </div>
    <div class="card-body">
      <div class="d-flex flex-column flex-md-row">
        <div class="flex-grow-1">
          <label class="text-muted">{{ __('Status') }}</label>
          <geo-design-status :status="syncStatus" />
        </div>
        <geo-design-time-ago
          v-for="(timeAgo, index) in timeAgoArray"
          :key="index"
          class="flex-grow-1"
          :label="timeAgo.label"
          :date-string="timeAgo.dateString"
          :default-text="timeAgo.defaultText"
        />
      </div>
    </div>
  </div>
</template>
