<script>
import { GlButton } from '@gitlab/ui';
import { n__, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';

export default {
  components: {
    GlButton,
    Icon,
    UserAvatarList,
  },
  props: {
    rules: {
      type: Array,
      required: true,
      default: () => [],
    },
  },
  methods: {
    summaryText(rule) {
      return sprintf(
        n__(
          '%d approval required from %{name}',
          '%d approvals required from %{name}',
          rule.approvalsRequired,
        ),
        { name: rule.name },
      );
    },
  },
};
</script>

<template>
  <table class="table">
    <thead class="thead-white text-nowrap">
      <tr class="d-none d-sm-table-row">
        <th>{{ s__('ApprovalRule|Name') }}</th>
        <th class="w-50">{{ s__('ApprovalRule|Members') }}</th>
        <th>{{ s__('ApprovalRule|No. approvals required') }}</th>
        <th></th>
      </tr>
    </thead>
    <tbody>
      <tr v-for="rule in rules" :key="rule.id">
        <td>
          <div class="d-none d-sm-block">{{ rule.name }}</div>
          <div class="d-block d-sm-none">{{ summaryText(rule) }}</div>
        </td>
        <td class="d-none d-sm-table-cell">
          <div v-if="!rule.approvers.length">{{ __('None') }}</div>
          <user-avatar-list v-else :items="rule.approvers" :img-size="24" />
        </td>
        <td class="d-none d-sm-table-cell">
          <icon name="approval" class="align-top text-tertiary" />
          <span>{{ rule.approvalsRequired }}</span>
        </td>
        <td class="text-nowrap px-2 w-0">
          <gl-button variant="none" @click="$emit('edit', rule);">
            <icon name="pencil" :aria-label="__('Edit')" /> </gl-button
          ><gl-button
            class="prepend-left-8 btn-inverted"
            variant="remove"
            @click="$emit('remove', rule);"
          >
            <icon name="remove" :aria-label="__('Remove')" />
          </gl-button>
        </td>
      </tr>
    </tbody>
  </table>
</template>
