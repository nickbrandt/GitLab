<script>
import BoardCardLoadingSkeleton from '~/boards/components/board_card_loading_skeleton.vue';

export default {
  components: {
    BoardCardLoadingSkeleton,
  },
};
</script>

<template>
  <div class="gl-px-3">
    <div class="gl-mt-5 gl-bg-gray-10 gl-display-inline-flex gl-rounded-base">
      <div class="gl-px-3 gl-pt-3">
        <board-card-loading-skeleton />
      </div>
      <div class="gl-px-3 gl-pt-3">
        <board-card-loading-skeleton />
      </div>
      <div class="gl-px-3 gl-pt-3">
        <board-card-loading-skeleton />
      </div>
    </div>
    <div class="gl-mt-5 gl-bg-gray-10 gl-display-inline-flex gl-rounded-base">
      <div class="gl-px-3 gl-pt-3">
        <board-card-loading-skeleton />
      </div>
      <div class="gl-px-3 gl-pt-3">
        <board-card-loading-skeleton />
      </div>
      <div class="gl-px-3 gl-pt-3">
        <board-card-loading-skeleton />
      </div>
    </div>
  </div>
</template>
