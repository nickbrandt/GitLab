<script>
import { GlTabs, GlTab } from '@gitlab/ui';

export default {
  components: {
    GlTabs,
    GlTab,
  },
};
</script>

<template>
  <gl-tabs content-class="gl-display-none" v-bind="$attrs" justified v-on="$listeners">
    <gl-tab :title-link-attributes="{ 'data-testid': 'create-group-tab' }" no-body>
      <template #title>
        <span class="gl-display-none gl-sm-display-block!">{{
          s__('GroupsNew|Create group')
        }}</span>
        <span class="gl-display-block gl-sm-display-none!">{{ s__('GroupsNew|Create') }}</span>
      </template>
    </gl-tab>
    <gl-tab :title-link-attributes="{ 'data-testid': 'import-group-tab' }" no-body>
      <template #title>
        <span class="gl-display-none gl-sm-display-block!">{{
          s__('GroupsNew|Import group')
        }}</span>
        <span class="gl-display-block gl-sm-display-none!">{{ s__('GroupsNew|Import') }}</span>
      </template>
    </gl-tab>
  </gl-tabs>
</template>
