<script>
export default {
  name: 'ReportItemModuleLocation',
  components: {
  },
  props: {
    module: {
      type: String,
      required: true
    },
    offset: {
      type: Number,
      required: true
    }
  },
  computed: {
    hexOffset() {
      let res = Math.floor(this.offset).toString(16);
      if (res.length % 2 !== 0) {
        res = `0${res}`;
      }
      return `0x${res}`;
    }
  },
};
</script>

<template>
  <div>
    <code>{{module}}+{{hexOffset}}</code>
  </div>
</template>
