<script>
export default {
  props: {
    filterBy: {
      type: String,
      required: true,
    },
    showCreateRequirement: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <div class="card card-small card-without-border">
    <!-- eslint-disable-next-line @gitlab/vue-i18n/no-bare-strings -->
    <h3 v-if="showCreateRequirement">Create Requirement Form visible!</h3>
    <!-- eslint-disable-next-line @gitlab/vue-i18n/no-bare-strings -->
    <h2>Hello World from Requirements app!</h2>
  </div>
</template>
