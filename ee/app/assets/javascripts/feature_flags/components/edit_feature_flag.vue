<script>
import { GlLoadingIcon, GlToggle } from '@gitlab/ui';
import { createNamespacedHelpers } from 'vuex';
import { sprintf, s__ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import store from '../store/index';
import FeatureFlagForm from './form.vue';

const { mapState, mapActions } = createNamespacedHelpers('edit');

export default {
  store,
  components: {
    GlLoadingIcon,
    GlToggle,
    FeatureFlagForm,
  },
  mixins: [glFeatureFlagMixin()],
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
    ...mapState([
      'error',
      'name',
      'description',
      'scopes',
      'isLoading',
      'hasError',
      'iid',
      'active',
    ]),
    title() {
      return this.hasFeatureFlagsIID
        ? `^${this.iid} ${this.name}`
        : sprintf(s__('Edit %{name}'), { name: this.name });
    },
    hasFeatureFlagsIID() {
      return this.glFeatures.featureFlagIID && this.iid;
    },
    hasFeatureFlagToggle() {
      return this.glFeatures.featureFlagToggle;
    },
  },
  created() {
    this.setPath(this.path);
    return this.setEndpoint(this.endpoint).then(() => this.fetchFeatureFlag());
  },
  methods: {
    ...mapActions([
      'updateFeatureFlag',
      'setEndpoint',
      'setPath',
      'fetchFeatureFlag',
      'toggleActive',
    ]),
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="isLoading" />

    <template v-else-if="!isLoading && !hasError">
      <div class="d-flex align-items-center mb-3 mt-3">
        <gl-toggle
          v-if="hasFeatureFlagToggle"
          :value="active"
          class="m-0 mr-3"
          @change="toggleActive"
        />
        <h3 class="page-title m-0">{{ title }}</h3>
      </div>

      <div v-if="error.length" class="alert alert-danger">
        <p v-for="(message, index) in error" :key="index" class="mb-0">{{ message }}</p>
      </div>

      <feature-flag-form
        :name="name"
        :description="description"
        :scopes="scopes"
        :cancel-path="path"
        :submit-text="__('Save changes')"
        :environments-endpoint="environmentsEndpoint"
        :active="active || !hasFeatureFlagToggle"
        @handleSubmit="data => updateFeatureFlag(data)"
      />
    </template>
  </div>
</template>
