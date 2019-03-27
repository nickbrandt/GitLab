<script>
import { __, sprintf } from '~/locale';
import { GlLoadingIcon } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  components: {
    GlLoadingIcon,
    Icon,
  },
  mixins: [timeagoMixin],
  props: {
    isLoading: {
      type: Boolean,
      required: true,
    },
    name: {
      type: String,
      required: false,
      default: '',
    },
    updatedAt: {
      type: String,
      required: false,
      default: '',
    },
    updatedBy: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    updatedText() {
      return sprintf(__('Updated %{updated_at} by %{updated_by}'), {
        updated_at: this.timeFormated(this.updatedAt),
        updated_by: this.updatedBy.name,
      });
    },
  },
};
</script>

<template>
  <header class="d-flex w-100 p-2 bg-white align-items-center js-design-header">
    <router-link
      :to="{ name: 'designs' }"
      :aria-label="s__('DesignManagement|Go back to designs')"
      class="mr-3 text-plain"
    >
      <icon :size="18" name="close" />
    </router-link>
    <div>
      <gl-loading-icon v-if="isLoading" size="md" class="mt-2 mb-2" />
      <template v-else>
        <h2 class="m-0">{{ name }}</h2>
        <small class="text-secondary">{{ updatedText }}</small>
      </template>
    </div>
  </header>
</template>
