export default {
  data() {
    return {
      isInputFocused: false,
    };
  },
  methods: {
    onFocus() {
      this.isInputFocused = true;
      this.$emit('focus');
    },
    onBlur() {
      this.isInputFocused = false;
      this.$emit('blur');
    },
  },
};
