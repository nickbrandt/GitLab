<script>
export default {
  props: {
    illustrationPath: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <div class="text-center">
    <div v-if="illustrationPath" class="svg-content svg-130"><img :src="illustrationPath" /></div>
    <h4>{{ __('Web Terminal') }}</h4>
    <p>{{ __('Run tests against your code live using the Web Terminal') }}</p>
    <div class="bs-callout text-left">The Web Terminal is coming soon. Stay tuned!</div>
  </div>
</template>
