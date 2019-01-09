<script>
import App from './app_base.vue';
import RulesInput from './rules_input.vue';

export default {
  components: {
    App,
    RulesInput,
  },
};
</script>

<template>
  <app> <rules-input slot="rules" slot-scope="{ rules }" :rules="rules" /> </app>
</template>
