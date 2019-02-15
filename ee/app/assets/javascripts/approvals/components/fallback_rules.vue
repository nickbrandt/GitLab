<script>
import { mapState } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import Rules from './rules.vue';
import RuleControls from './rule_controls.vue';

export default {
  components: {
    Icon,
    UserAvatarList,
    Rules,
    RuleControls,
  },
  props: {
    hasControls: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    ...mapState({
      approvalsRequired: state => state.approvals.fallbackApprovalsRequired,
      minApprovalsRequired: state => state.approvals.minFallbackApprovalsRequired || 0,
    }),
    rules() {
      return [
        {
          isFallback: true,
          approvalsRequired: this.approvalsRequired,
          minApprovalsRequired: this.minApprovalsRequired,
        },
      ];
    },
  },
};
</script>

<template>
  <rules :rules="rules">
    <template slot="thead" slot-scope="{ members, approvalsRequired }">
      <tr class="d-none d-sm-table-row">
        <th class="w-75 pl-0">{{ members }}</th>
        <th>{{ approvalsRequired }}</th>
        <th v-if="hasControls"></th>
      </tr>
    </template>
    <template slot="tr" slot-scope="{ rule }">
      <td class="pl-0">
        {{ s__('ApprovalRule|All members with Developer role or higher and code owners (if any)') }}
      </td>
      <td class="text-nowrap">
        <slot
          name="approvals-required"
          :approvals-required="rule.approvalsRequired"
          :min-approvals-required="rule.minApprovalsRequired"
        >
          <icon name="approval" class="align-top text-tertiary" />
          <span>{{ rule.approvalsRequired }}</span>
        </slot>
      </td>
      <td v-if="hasControls" class="text-nowrap px-2 w-0">
        <rule-controls :rule="rule" />
      </td>
    </template>
  </rules>
</template>
