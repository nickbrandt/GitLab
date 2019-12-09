<script>
import { STATUS_ICON_NAMES, STATUS_ICON_CLASS, DEFAULT_STATUS } from '../store/constants';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'GeoDesignStatus',
  components: {
    Icon,
  },
  props: {
    status: {
      type: String,
      required: false,
      default: DEFAULT_STATUS,
    },
  },
  data() {
    return {
      icon: this.iconProperties(),
    };
  },
  methods: {
    iconProperties() {
      if (STATUS_ICON_NAMES[this.status] && STATUS_ICON_CLASS[this.status]) {
        return {
          name: STATUS_ICON_NAMES[this.status],
          cssClass: STATUS_ICON_CLASS[this.status],
        };
      }

      return {
        name: STATUS_ICON_NAMES[DEFAULT_STATUS],
        cssClass: STATUS_ICON_CLASS[DEFAULT_STATUS],
      };
    },
  },
};
</script>

<template>
  <div>
    <span class="d-flex align-items-center text-capitalize">
      <icon :name="icon.name" :class="icon.cssClass" class="mr-2" />
      {{ status }}
    </span>
  </div>
</template>
