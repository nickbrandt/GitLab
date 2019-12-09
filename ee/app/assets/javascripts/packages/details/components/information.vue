<script>
import { s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

export default {
  name: 'PackageInformation',
  components: {
    ClipboardButton,
  },
  props: {
    heading: {
      type: String,
      default: s__('Package information'),
      required: false,
    },
    information: {
      type: Array,
      default: () => [],
      required: true,
    },
    showCopy: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <div class="card">
    <div class="card-header">
      <strong>{{ heading }}</strong>
    </div>

    <ul class="content-list">
      <li v-for="(item, index) in information" :key="index">
        <span class="text-secondary">{{ item.label }}</span>
        <div class="pull-right">
          <span>{{ item.value }}</span>
          <clipboard-button
            v-if="showCopy"
            :text="item.value"
            :title="sprintf(__('Copy %{field}'), { field: item.label })"
            css-class="border-0 text-secondary py-0"
          />
        </div>
      </li>
    </ul>
  </div>
</template>
