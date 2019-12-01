<script>
export default {
  name: 'StageCardListItem',
  props: {
    isActive: {
      type: Boolean,
      required: true,
    },
    canEdit: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  data() {
    return {
      activeClass: 'active font-weight-bold border-color-blue-300',
      inactiveClass: 'bg-transparent border-color-default',
    };
  },
};
</script>

<template>
  <div
    :class="[isActive ? activeClass : inactiveClass]"
    class="stage-nav-item d-flex pl-4 pr-4 m-0 mb-1 ml-2 rounded border-width-1px border-style-solid"
  >
    <slot></slot>
  </div>
</template>
