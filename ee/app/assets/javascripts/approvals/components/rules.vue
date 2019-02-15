<script>
import { s__ } from '~/locale';

const HEADERS = {
  name: s__('ApprovalRule|Name'),
  members: s__('ApprovalRule|Members'),
  approvalsRequired: s__('ApprovalRule|No. approvals required'),
};

export default {
  props: {
    rules: {
      type: Array,
      required: true,
    },
  },
  HEADERS,
};
</script>

<template>
  <table class="table m-0">
    <thead class="thead-white text-nowrap">
      <slot name="thead" v-bind="$options.HEADERS"></slot>
    </thead>
    <tbody>
      <tr v-for="rule in rules" :key="rule.id">
        <slot :rule="rule" name="tr"></slot>
      </tr>
    </tbody>
  </table>
</template>
