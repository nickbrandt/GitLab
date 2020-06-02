<script>
export default {
  stickyHeight: process.env.NODE_ENV === 'development' ? '75px' : '40px',
  computed: {
    hasHeaderSlot() {
      return Boolean(this.$slots.header);
    },
    hasStickySlot() {
      return Boolean(this.$slots.sticky);
    },
    stickyClasses() {
      return this.hasStickySlot ? ['position-sticky', 'gl-z-index-2'] : [];
    },
    hasAsideSlot() {
      return Boolean(this.$slots.aside);
    },
  },
};
</script>

<template>
  <section>
    <header v-if="hasHeaderSlot">
      <slot name="header"></slot>
    </header>

    <section v-if="hasStickySlot" :class="stickyClasses" :style="{ top: $options.stickyHeight }">
      <slot name="sticky"></slot>
    </section>

    <div class="row mt-4">
      <article class="col" :class="{ 'col-xl-7': hasAsideSlot }">
        <slot></slot>
      </article>

      <aside v-if="hasAsideSlot" class="col-xl-5">
        <slot name="aside"></slot>
      </aside>
    </div>
  </section>
</template>
