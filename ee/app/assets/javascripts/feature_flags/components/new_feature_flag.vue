<script>
import { createNamespacedHelpers } from 'vuex';
import store from '../store/index';
import FeatureFlagForm from './form.vue';

const { mapState, mapActions } = createNamespacedHelpers('new');

export default {
  store,
  components: {
    FeatureFlagForm,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
    environmentsEndpoint: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(['error']),
    scopes() {
      return [
        {
          environment_scope: '*',
          active: true,
        },
      ];
    },
  },
  created() {
    this.setEndpoint(this.endpoint);
    this.setPath(this.path);
  },
  methods: {
    ...mapActions(['createFeatureFlag', 'setEndpoint', 'setPath']),
  },
};
</script>
<template>
  <div>
    <h3 class="page-title">{{ s__('FeatureFlags|New Feature Flag') }}</h3>

    <div v-if="error.length" class="alert alert-danger">
      <p v-for="(message, index) in error" :key="index" class="mb-0">{{ message }}</p>
    </div>

    <feature-flag-form
      :cancel-path="path"
      :submit-text="s__('FeatureFlags|Create feature flag')"
      :scopes="scopes"
      :environments-endpoint="environmentsEndpoint"
      @handleSubmit="data => createFeatureFlag(data)"
    />
  </div>
</template>
