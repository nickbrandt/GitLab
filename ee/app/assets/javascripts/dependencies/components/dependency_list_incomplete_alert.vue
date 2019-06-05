<script>
import DependencyListAlert from './dependency_list_alert.vue';

export default {
  name: 'DependencyListIncompleteAlert',
  components: {
    DependencyListAlert,
  },
  data() {
    return {
      dependencyFiles: [
        'package-lock.json',
        'composer.lock',
        'Gemfile.lock',
        'gems.locked',
        'yarn.lock',
        'requirements.txt',
        'pom.xml',
      ],
    };
  },
};
</script>

<template>
  <dependency-list-alert
    type="warning"
    :header-text="s__('Dependencies|Unsupported file(s) detected')"
    v-on="$listeners"
  >
    <p>
      {{
        __(
          'One or more of your dependency files are not supported, and the dependency list may be incomplete. Below is a list of supported file types.',
        )
      }}
    </p>
    <ul>
      <li v-for="file in dependencyFiles" :key="file">{{ file }}</li>
    </ul>
  </dependency-list-alert>
</template>
