<script>
import { GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';

const GITLAB_TEAM_MEMBER = __('GitLab Team Member');

export default {
  name: 'GitLabTeamMemberBadge',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: { GlIcon },
  created() {
    this.GITLAB_TEAM_MEMBER = GITLAB_TEAM_MEMBER;
  },
};
</script>

<template>
  <span
    v-gl-tooltip.hover
    :title="GITLAB_TEAM_MEMBER"
    role="img"
    :aria-label="GITLAB_TEAM_MEMBER"
    class="d-inline-block align-middle"
  >
    <gl-icon name="tanuki-verified" class="gl-text-purple d-block" />
  </span>
</template>
