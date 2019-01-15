<script>
import App from './app_base.vue';
import RulesInput from './rules_input.vue';
import RulesHiddenInputs from './rules_hidden_inputs.vue';

export default {
  components: {
    App,
    RulesInput,
    RulesHiddenInputs,
  },
};
</script>

<template>
  <app>
    <rules-input slot="rules" />
    <rules-hidden-inputs slot="footer" />
  </app>
</template>
