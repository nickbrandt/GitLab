<script>
export default {
  name: 'ReportItemHexInt',
  components: {
  },
  props: {
    value: {
      type: Number,
      required: true
    }
  },
  computed: {
    hexVal() {
      let res = Math.floor(this.value).toString(16);
      if (res.length % 2 !== 0) {
        res = `0${res}`;
      }
      return `0x${res}`;
    }
  },
};
</script>

<template>
  <code>{{hexVal}}</code>
</template>
