<script>
import DependencyListAlert from './dependency_list_alert.vue';

export default {
  name: 'DependencyListIncompleteAlert',
  components: {
    DependencyListAlert,
  },
};
</script>

<template>
  <dependency-list-alert type="warning" :header-text="__('Unsupported file(s) detected')">
    <p>
      {{
        __(
          'One or more of your dependency files are not supported, and the dependency list may be incomplete. Below is a list of supported file types.',
        )
      }}
    </p>
    <ul>
      <li>package-lock.json</li>
      <li>composer.lock</li>
      <li>Gemfile.lock</li>
      <li>gems.locked</li>
      <li>yarn.lock</li>
      <li>requirements.txt</li>
      <li>pom.xml</li>
    </ul>
  </dependency-list-alert>
</template>
