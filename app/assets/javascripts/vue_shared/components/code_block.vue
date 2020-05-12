<script>
export default {
  name: 'CodeBlock',
  props: {
    code: {
      type: String,
      required: true,
    },
    maxHeight: {
      type: String,
      required: false,
      default: 'initial',
    },
  },
  data() {
    return {
      isOverflowing: false,
      isExpanded: false,
    };
  },
  computed: {
    style() {
      return {
        maxHeight: this.isExpanded ? 'initial' : this.maxHeight,
        overflow: 'hidden',
      };
    },
  },
  mounted() {
    // need nextTick, otherwise `clientHeight` and `scrollHeight` will both be `0`
    this.$nextTick(() => {
      const { codeBlock } = this.$refs;
      const { clientHeight, scrollHeight } = codeBlock;
      this.isOverflowing = scrollHeight > clientHeight;
    });
  },
  methods: {
    toggleExpanded() {
      this.isExpanded = !this.isExpanded;
    },
  },
};
</script>
<template>
  <div>
    <pre
      class="code-block"
    ><code ref="codeBlock" class="d-block" :style="style">{{ code }}</code></pre>
    <button v-if="isOverflowing" @click="toggleExpanded">Show all</button>
  </div>
</template>
