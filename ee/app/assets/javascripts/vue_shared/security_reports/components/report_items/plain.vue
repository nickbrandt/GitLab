<script>

export default {
  name: 'ReportItemPlain',
  components: {
  },
  props: {
    value: {
      required: true
    }
  },
};
</script>

<template>
  <div>{{ value }}</div>
</template>
