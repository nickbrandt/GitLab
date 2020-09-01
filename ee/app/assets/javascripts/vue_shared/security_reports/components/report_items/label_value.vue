<script>
export default {
  name: 'ReportItemLabelValue',
  components: {
  },
  props: {
    value: {
      type: String,
      required: true,
    },
  },
}
</script>

<template>
    <span>{{value}}</span>
</template>
