<script>
import { GlBadge, GlButton, GlIcon } from '@gitlab/ui';
import query from '../queries/group_iteration.query.graphql';

export default {
  components: {
    GlBadge,
    GlButton,
    GlIcon,
  },
  apollo: {
    iteration: {
      query,
      variables() {
        return {
          groupPath: this.groupPath,
          id: this.iterationId,
        };
      },
      update(data) {
        console.log(data);

        return data.group.iterations.nodes[0];
      },
    },
  },
  props: {
    groupPath: {
      type: String,
      required: true,
    },
    iterationId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      title: 'Iteration TODO',
      startDate: '2020-05-01',
      dueDate: '2020-05-01',
    };
  },
};
</script>

<template>
  <div>
    <div class="gl-display-flex gl-justify-items-center gl-align-items-center gl-mt-5">
      <gl-badge variant="success">
        In Progress
      </gl-badge>
      {{ startDate }}
      -
      {{ dueDate }}
      <gl-button variant="link" class="gl-ml-auto">
        <gl-icon name="ellipsis_v" />
      </gl-button>
    </div>
    <hr />
    <div class="gl-display-flex">
      <h3 class="page-title">{{ title }}</h3>
    </div>
  </div>
</template>
