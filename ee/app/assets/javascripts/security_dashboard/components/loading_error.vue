<script>
import { GlEmptyState } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import { LOADING_VULNERABILITIES_ERROR_CODES as ERROR_CODES } from '../store/modules/vulnerabilities/constants';
import { imagePath } from '~/lib/utils/common_utils';

const description = s__(
  'Security Reports|Security reports can only be accessed by authorized users.',
);

export default {
  emptyStatePropsMap: {
    [ERROR_CODES.UNAUTHORIZED]: {
      title: s__('Security Reports|You must sign in as an authorized user to see this report'),
      description,
      primaryButtonText: __('Sign in'),
      primaryButtonLink: '/users/sign_in',
      svgPath: imagePath('illustrations/user-not-logged-in.svg'),
    },
    [ERROR_CODES.FORBIDDEN]: {
      title: s__('Security Reports|You do not have sufficient permissions to access this report'),
      description,
      svgPath: imagePath('illustrations/lock_promotion.svg'),
    },
  },
  components: {
    GlEmptyState,
  },
  props: {
    errorCode: {
      type: Number,
      required: true,
      validator: value => Object.values(ERROR_CODES).includes(value),
    },
  },
};
</script>

<template>
  <gl-empty-state v-bind="$options.emptyStatePropsMap[errorCode]" />
</template>
