<script>
const FORMAT_DEFAULT = 'default';
const FORMAT_HEX = 'hex';
const VALID_FORMATS = [FORMAT_DEFAULT, FORMAT_HEX];

export default {
  name: 'ReportItemInt',
  props: {
    value: {
      type: Number,
      required: true,
    },
    format: {
      type: String,
      required: false,
      default: 'default',
      validator: val => VALID_FORMATS.includes(val),
    },
  },
  computed: {
    displayVal() {
      switch (this.format) {
        case FORMAT_HEX:
          return this.hexVal();
        case FORMAT_DEFAULT:
        default:
          return this.value;
      }
    },
  },
  methods: {
    hexVal() {
      let res = Math.floor(this.value).toString(16);
      if (res.length % 2 !== 0) {
        res = `0${res}`;
      }
      return `0x${res}`;
    },
  },
};
</script>

<template>
  <div>
    <code :title="value">{{ displayVal }}</code>
  </div>
</template>
