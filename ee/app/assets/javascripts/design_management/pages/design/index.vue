<script>
export default {
  props: {
    id: {
      type: Number,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    Design detail for {{ id }}
    <router-link to="/designs">All designs</router-link>
  </div>
</template>
