<script>
import App from './app_base.vue';
import RulesSettings from './rules_settings.vue';

export default {
  components: {
    App,
    RulesSettings,
  },
};
</script>

<template>
  <app> <rules-settings slot="rules" slot-scope="{ rules }" :rules="rules" /> </app>
</template>
