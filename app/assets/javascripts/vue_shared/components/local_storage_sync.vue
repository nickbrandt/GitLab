<script>
import { isString } from 'lodash';

export default {
  props: {
    storageKey: {
      type: String,
      required: true,
    },
    value: {
      type: [String, Boolean, Number, Object],
      required: false,
      default: '',
    },
  },
  watch: {
    value(newVal) {
      this.saveValue(newVal);
    },
  },
  mounted() {
    // On mount, trigger update if we actually have a localStorageValue
    const value = this.getValue();

    if (value && this.value !== value) {
      this.$emit('input', value);
    }
  },
  methods: {
    getValue() {
      const rawValue = localStorage.getItem(this.storageKey);

      try {
        return JSON.parse(rawValue);
      } catch {
        return rawValue;
      }
    },
    saveValue(val) {
      const valToStore = isString(val) ? val : JSON.stringify(val);
      localStorage.setItem(this.storageKey, valToStore);
    },
  },
  render() {
    return this.$slots.default;
  },
};
</script>
