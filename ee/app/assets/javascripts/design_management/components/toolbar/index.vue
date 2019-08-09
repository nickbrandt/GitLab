<script>
import { __, sprintf } from '~/locale';
import { GlLoadingIcon } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import Pagination from './pagination.vue';

export default {
  components: {
    GlLoadingIcon,
    Icon,
    Pagination,
  },
  mixins: [timeagoMixin],
  props: {
    id: {
      type: String,
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
      default: null,
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
      <h2 class="m-0">{{ name }}</h2>
      <small v-if="updatedAt" class="text-secondary">{{ updatedText }}</small>
    </div>
    <pagination :id="id" class="ml-auto" />
  </header>
</template>
