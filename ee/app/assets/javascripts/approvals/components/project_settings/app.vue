<script>
import App from '../app.vue';
import ProjectRules from './project_rules.vue';

export default {
  components: {
    App,
    ProjectRules,
  },
};
</script>

<template>
  <app><project-rules slot="rules"/></app>
</template>
