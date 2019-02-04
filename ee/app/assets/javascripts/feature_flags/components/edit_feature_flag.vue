<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { createNamespacedHelpers } from 'vuex';
import { sprintf, s__ } from '~/locale';
import store from '../store/index';
import FeatureFlagForm from './form.vue';

const { mapState, mapActions } = createNamespacedHelpers('edit');

export default {
  store,
  components: {
    GlLoadingIcon,
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
  },
  computed: {
    ...mapState(['error', 'name', 'description', 'scopes', 'isLoading', 'hasError']),
    title() {
      return sprintf(s__('Edit %{name}'), { name: this.name });
    },
  },
  created() {
    this.setPath(this.path);
    return this.setEndpoint(this.endpoint).then(() => this.fetchFeatureFlag());
  },
  methods: {
    ...mapActions(['updateFeatureFlag', 'setEndpoint', 'setPath', 'fetchFeatureFlag']),
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="isLoading" />

    <template v-else-if="!isLoading && !hasError">
      <h3 class="page-title">{{ title }}</h3>

      <div v-if="error.length" class="alert alert-danger">
        <p v-for="(message, index) in error" :key="index" class="mb-0">{{ message }}</p>
      </div>

      <feature-flag-form
        :name="name"
        :description="description"
        :scopes="scopes"
        :cancel-path="path"
        :submit-text="__('Save changes')"
        @handleSubmit="data => updateFeatureFlag(data)"
      />
    </template>
  </div>
</template>
