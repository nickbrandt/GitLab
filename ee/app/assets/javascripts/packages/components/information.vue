<script>
import { s__ } from '~/locale';

export default {
  name: 'PackageInformation',
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
  },
};
</script>

<template>
  <div class="col-sm-6">
    <div class="card">
      <div class="card-header">
        <strong>{{ heading }}</strong>
      </div>

      <ul class="content-list">
        <li v-for="(item, index) in information" :key="index">
          <span class="text-secondary">{{ item.label }}</span>
          <span class="pull-right">{{ item.value }}</span>
        </li>
      </ul>
    </div>
  </div>
</template>
