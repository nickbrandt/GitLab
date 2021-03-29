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
    <div class="gl-mt-6 gl-bg-gray-100 gl-display-inline-flex gl-rounded-base">
      <div class="gl-px-3 gl-pt-3 gl-mr-3">
        <board-card-loading-skeleton />
      </div>
      <div class="gl-px-3 gl-pt-3 gl-mr-3">
        <board-card-loading-skeleton />
      </div>
      <div class="gl-px-3 gl-pt-3 gl-mr-3">
        <board-card-loading-skeleton />
      </div>
      <div class="gl-px-3 gl-pt-3">
        <board-card-loading-skeleton />
      </div>
    </div>
    <br />
    <div class="gl-mt-6 gl-bg-gray-100 gl-display-inline-flex gl-rounded-base">
      <div class="gl-px-3 gl-pt-3 gl-mr-3">
        <board-card-loading-skeleton />
      </div>
      <div class="gl-px-3 gl-pt-3 gl-mr-3">
        <board-card-loading-skeleton />
      </div>
      <div class="gl-px-3 gl-pt-3 gl-mr-3">
        <board-card-loading-skeleton />
      </div>
      <div class="gl-px-3 gl-pt-3">
        <board-card-loading-skeleton />
      </div>
    </div>
    <br />
    <div class="gl-mt-6 gl-bg-gray-100 gl-display-inline-flex gl-rounded-base">
      <div class="gl-px-3 gl-pt-3 gl-mr-3">
        <board-card-loading-skeleton />
      </div>
      <div class="gl-px-3 gl-pt-3 gl-mr-3">
        <board-card-loading-skeleton />
      </div>
      <div class="gl-px-3 gl-pt-3 gl-mr-3">
        <board-card-loading-skeleton />
      </div>
      <div class="gl-px-3 gl-pt-3">
        <board-card-loading-skeleton />
      </div>
    </div>
  </div>
</template>
