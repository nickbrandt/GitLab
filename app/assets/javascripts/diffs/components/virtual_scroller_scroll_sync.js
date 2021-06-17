export default {
  inject: ['vscrollParent'],
  props: {
    index: {
      type: Number,
      required: true,
    },
  },
  watch: {
    index: {
      handler() {
        if (this.index < 0) return;

        if (this.vscrollParent.itemsWithSize[this.index].size) {
          this.scrollToIndex();
        } else {
          this.$_itemsWithSizeWatcher = this.$watch('vscrollParent.itemsWithSize', async () => {
            await this.$nextTick();

            if (this.vscrollParent.itemsWithSize[this.index].size) {
              this.$_itemsWithSizeWatcher();
              this.scrollToIndex();
            }
          });
        }
      },
      immediate: true,
    },
  },
  beforeDestroy() {
    if (this.$_itemsWithSizeWatcher) this.$_itemsWithSizeWatcher();
  },
  methods: {
    scrollToIndex() {
      this.vscrollParent.scrollToItem(this.index);
    },
  },
  render(h) {
    return h(null);
  },
};
