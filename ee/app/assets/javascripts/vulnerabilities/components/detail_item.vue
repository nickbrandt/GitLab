<script>
import { GlSprintf } from '@gitlab/ui';

export default {
  components: { GlSprintf },
  props: {
    sprintfMessage: { type: String, required: true },
  },
  computed: {
    valueName() {
      // Get the name of the placeholder that's not %{labelStart} or %{labelEnd}.
      return this.sprintfMessage.match(/%{(?!(labelStart|labelEnd))(.+)}/)[2];
    },
  },
};
</script>

<template>
  <li :data-testid="valueName">
    <gl-sprintf :message="sprintfMessage">
      <template #label="{ content }">
        <strong>{{ content }}</strong>
      </template>
      <template #[valueName]>
        <slot></slot>
      </template>
    </gl-sprintf>
  </li>
</template>
