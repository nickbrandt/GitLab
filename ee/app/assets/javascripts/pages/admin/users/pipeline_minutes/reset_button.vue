<script>
import { GlButton } from '@gitlab/ui';

export default {
  components: {
    GlButton,
  },
  inject: {
    resetMinutesPath: {
      type: String,
      default: '',
    },
  },
};
</script>
<template>
  <div class="bs-callout clearfix gl-mt-0 gl-mb-0">
    <h4>
      {{ s__('SharedRunnersMinutesSettings|Reset used pipeline minutes') }}
    </h4>
    <p>
      {{
        s__(
          'SharedRunnersMinutesSettings|By resetting the pipeline minutes for this namespace, the currently used minutes will be set to zero.',
        )
      }}
    </p>
    <gl-button target="_self" :href="resetMinutesPath" data-method="post">
      {{ s__('SharedRunnersMinutesSettings|Reset pipeline minutes') }}
    </gl-button>
  </div>
</template>
