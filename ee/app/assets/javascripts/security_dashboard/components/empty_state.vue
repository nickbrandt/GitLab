<script>
import { GlButton } from '@gitlab/ui';

export default {
  name: 'EmptyState',
  components: {
    GlButton,
  },
  props: {
    svgPath: {
      type: String,
      required: true,
    },
    link: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="empty-state row">
    <div class="col-12">
      <div class="svg-content svg-250">
        <img :src="svgPath" :alt="s__('Security Reports|No Vulnerabilities')" />
      </div>
      <div class="text-content">
        <h4>{{ s__("Security Reports|We've found no vulnerabilities for your group") }}</h4>
        <p>
          {{
            s__(
              "Security Reports|While it's rare to have no vulnerabilities for your group, it can happen. In any event, we ask that you please double check your settings to make sure you've set up your dashboard correctly.",
            )
          }}
        </p>
        <div class="text-center">
          <gl-button variant="success" :href="link">{{
            s__('Security Reports|Learn more about setting up your dashboard')
          }}</gl-button>
        </div>
      </div>
    </div>
  </div>
</template>
