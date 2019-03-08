<script>
import { s__, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'EventItem',
  components: {
    Icon,
  },
  props: {
    type: {
      type: String,
      required: true,
    },
    authorName: {
      type: String,
      required: true,
    },
    authorUsername: {
      type: String,
      required: true,
    },
    projectName: {
      type: String,
      required: false,
      default: '',
    },
    projectLink: {
      type: String,
      required: false,
      default: '',
    },
    actionLinkText: {
      type: String,
      required: true,
    },
    actionLinkUrl: {
      type: String,
      required: true,
    },
  },
  typeMap: {
    issue: {
      name: s__('Reports|issue'),
      icon: 'issue-created',
    },
    mergeRequest: {
      name: s__('Reports|merge request'),
      icon: 'merge-request',
    },
  },
  computed: {
    typeData() {
      return this.$options.typeMap[this.type] || {};
    },
    iconName() {
      return this.typeData.icon || 'plus';
    },
    createdText() {
      return sprintf(s__('ciReport|Created %{eventType}'), { eventType: this.typeData.name });
    },
  },
};
</script>

<template>
  <div class="card-body d-flex align-items-center">
    <div class="circle-icon-container ci-status-icon-success">
      <icon :size="16" :name="iconName" />
    </div>
    <div class="ml-3">
      <div>
        <strong class="js-author-name">{{ authorName }}</strong>
        <em class="js-username">@{{ authorUsername }}</em>
      </div>
      <div>
        <span v-if="typeData.name" class="js-created">{{ createdText }}</span>
        <a class="js-action-link" :title="actionLinkText" :href="actionLinkUrl">
          {{ actionLinkText }}
        </a>
        <template v-if="projectName">
          <span>{{ __('at') }} </span>
          <a class="js-project-name" :title="projectName" :href="projectLink">{{ projectName }}</a>
        </template>
      </div>
    </div>
  </div>
</template>
