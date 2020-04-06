<script>
export default {
  computed: {
    hasHeaderSlot() {
      return Boolean(this.$slots.header);
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
