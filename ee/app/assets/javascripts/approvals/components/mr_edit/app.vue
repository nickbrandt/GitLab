<script>
import App from '../app.vue';
import MrRules from './mr_rules.vue';
import MrRulesHiddenInputs from './mr_rules_hidden_inputs.vue';
import MrFallbackRules from './mr_fallback_rules.vue';

export default {
  components: {
    App,
    MrRules,
    MrRulesHiddenInputs,
    MrFallbackRules,
  },
};
</script>

<template>
  <app>
    <mr-fallback-rules slot="fallback" />
    <mr-rules slot="rules" />
    <mr-rules-hidden-inputs slot="footer" />
  </app>
</template>
