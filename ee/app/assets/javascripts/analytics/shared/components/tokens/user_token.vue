<script>
import {
  GlAvatar,
  GlFilteredSearchToken,
  GlFilteredSearchSuggestion,
  GlLoadingIcon,
} from '@gitlab/ui';

export default {
  components: {
    GlAvatar,
    GlFilteredSearchToken,
    GlFilteredSearchSuggestion,
    GlLoadingIcon,
  },
  inheritAttrs: false,
  props: {
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
  },
  computed: {
    users() {
      return this.config.users;
    },
    selectedUser() {
      return this.value?.data
        ? this.config.users.find(({ username }) => username === this.value.data)
        : {};
    },
  },
};
</script>
<template>
  <gl-filtered-search-token :config="config" v-bind="{ ...$props, ...$attrs }" v-on="$listeners">
    <template #view="{ inputValue }">
      <div v-if="selectedUser" data-testid="selected-user">
        <gl-avatar :size="16" :src="selectedUser.avatar_url" />
        <span>{{ inputValue }}</span>
      </div>
    </template>
    <template #suggestions>
      <gl-loading-icon v-if="config.isLoading" />
      <template v-else>
        <gl-filtered-search-suggestion
          v-for="user in users"
          :key="user.username"
          :value="user.username"
          data-testid="user-item"
        >
          <div class="d-flex">
            <gl-avatar :size="32" :src="user.avatar_url" />
            <div>
              <div>{{ user.name }}</div>
              <div>@{{ user.username }}</div>
            </div>
          </div>
        </gl-filtered-search-suggestion>
      </template>
    </template>
  </gl-filtered-search-token>
</template>
