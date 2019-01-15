<script>
import { mapState, mapActions } from 'vuex';
import _ from 'underscore';
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import ApproversList from './approvers_list.vue';
import ApproversSelect from './approvers_select.vue';
import { TYPE_USER, TYPE_GROUP } from '../constants';

export default {
  components: {
    ApproversList,
    ApproversSelect,
    GlButton,
  },
  props: {
    initRule: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      name: '',
      approvalsRequired: 1,
      approvers: [],
      approversToAdd: [],
      showValidation: false,
      ...this.getInitialData(),
    };
  },
  computed: {
    ...mapState({ projectId: state => state.settings.projectId }),
    approversByType() {
      return _.groupBy(this.approvers, x => x.type);
    },
    users() {
      return this.approversByType[TYPE_USER] || [];
    },
    groups() {
      return this.approversByType[TYPE_GROUP] || [];
    },
    userIds() {
      return this.users.map(x => x.id);
    },
    groupIds() {
      return this.groups.map(x => x.id);
    },
    validation() {
      if (!this.showValidation) {
        return {};
      }

      return {
        name: this.invalidName,
        approvalsRequired: this.invalidApprovalsRequired,
      };
    },
    invalidName() {
      return !this.name ? __('Please provide a name') : '';
    },
    invalidApprovalsRequired() {
      return !_.isNumber(this.approvalsRequired) || this.approvalsRequired < 0
        ? __('Please enter a non-negative number')
        : '';
    },
    isValid() {
      return Object.keys(this.validation).every(key => !this.validation[key]);
    },
  },
  methods: {
    ...mapActions(['postRule', 'putRule']),
    addSelection() {
      if (!this.approversToAdd.length) {
        return;
      }

      this.approvers = this.approversToAdd.concat(this.approvers);
      this.approversToAdd = [];
    },
    submit() {
      const id = this.initRule && this.initRule.id;
      const data = {
        name: this.name,
        approvalsRequired: this.approvalsRequired,
        users: this.userIds,
        groups: this.groupIds,
        userRecords: this.users,
        groupRecords: this.groups,
      };

      this.showValidation = true;
      if (!this.isValid) {
        return Promise.resolve();
      }

      return id ? this.putRule({ id, ...data }) : this.postRule(data);
    },
    getInitialData() {
      if (!this.initRule) {
        return {};
      }

      const users = this.initRule.users.map(x => ({ ...x, type: TYPE_USER }));
      const groups = this.initRule.groups.map(x => ({ ...x, type: TYPE_GROUP }));

      return {
        name: this.initRule.name,
        approvalsRequired: this.initRule.approvalsRequired,
        approvers: groups.concat(users),
      };
    },
  },
};
</script>

<template>
  <form novalidate @submit.prevent.stop="submit">
    <div class="row">
      <div class="form-group col-sm-6">
        <label class="label-wrapper">
          <span class="form-label label-bold">{{ s__('ApprovalRule|Name') }}</span>
          <input
            v-model="name"
            :class="{ 'is-invalid': validation.name }"
            class="form-control"
            name="name"
            type="text"
          />
          <span class="invalid-feedback">{{ validation.name }}</span>
          <span class="text-secondary">{{ s__('ApprovalRule|e.g. QA, Security, etc.') }}</span>
        </label>
      </div>
      <div class="form-group col-sm-6">
        <label class="label-wrapper">
          <span class="form-label label-bold">{{
            s__('ApprovalRule|No. approvals required')
          }}</span>
          <input
            v-model.number="approvalsRequired"
            :class="{ 'is-invalid': validation.approvalsRequired }"
            class="form-control mw-6em"
            name="approvals_required"
            type="number"
            min="0"
          />
          <span class="invalid-feedback">{{ validation.approvalsRequired }}</span>
        </label>
      </div>
    </div>
    <div class="form-group">
      <label class="label-bold">{{ s__('ApprovalRule|Members') }}</label>
      <div class="d-flex align-items-start">
        <div class="w-100">
          <approvers-select
            v-model="approversToAdd"
            :project-id="projectId"
            :skip-user-ids="userIds"
            :skip-group-ids="groupIds"
          />
        </div>
        <gl-button variant="success" class="btn-inverted prepend-left-8" @click="addSelection">
          {{ __('Add') }}
        </gl-button>
      </div>
    </div>
    <div class="bordered-box overflow-auto h-13em"><approvers-list v-model="approvers" /></div>
  </form>
</template>
