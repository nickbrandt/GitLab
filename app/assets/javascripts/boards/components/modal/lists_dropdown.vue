<script>
import { GlDropdown, GlDropdownItem, GlDropdownHeader, GlDropdownDivider } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import ModalStore from '../../stores/modal_store';
import boardsStore from '../../stores/boards_store';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownHeader,
    GlDropdownDivider,
    UserAvatarImage,
    Icon,
  },
  data() {
    return {
      modal: ModalStore.store,
      state: boardsStore.state,
    };
  },
  computed: {
    selected() {
      return this.modal.selectedList || this.state.lists[1];
    },
    labelLists() {
      return this.state.lists.filter(l => l.type === 'label');
    },
    assigneeLists() {
      return this.state.lists.filter(l => l.type === 'assignee');
    },
    milestoneLists() {
      return this.state.lists.filter(l => l.type === 'milestone');
    },
  },
  destroyed() {
    this.modal.selectedList = null;
  },
};
</script>
<template>
  <div class="dropdown inline">
    <gl-dropdown>
      <template slot="button-content">
        <span class="str-truncated-100 mr-2">
          <template v-if="selected.type === 'label'">
            <span :style="{ backgroundColor: selected.label.color }" class="dropdown-label-box"> </span>
            {{ selected.title }}
          </template>
          <template v-if="selected.type === 'assignee'">
            <user-avatar-image 
              :img-src="selected.avatar_url"
              :img-alt="selected.name"
              :img-size="24"
            />
            {{ selected.title }}
          </template>
          <template v-if="selected.type === 'milestone'">
            {{ selected.title }}
          </template>
        </span>
        <icon name="chevron-down" class="ml-auto" />
      </template>
      <section>
        <gl-dropdown-header>{{ __('Label') }}</gl-dropdown-header>
        <ul>
          <li v-for="(list, i) in labelLists" :key="i">
            <gl-dropdown-item
              :class="{ 'is-active': list.id == selected.id }"
              @click.prevent="modal.selectedList = list"
            >
              <span :style="{ backgroundColor: list.label.color }" class="dropdown-label-box"> </span>
              {{ list.title }}
            </gl-dropdown-item>
          </li>
        </ul>
      </section>
      <gl-dropdown-divider />
      <section>
        <gl-dropdown-header>{{ __('Assignee') }}</gl-dropdown-header>
        <ul>
          <li v-for="(assigneeList, i) in assigneeLists" :key="i">
            <gl-dropdown-item
              :class="{ 'is-active': assigneeList.id == selected.id }"
              @click.prevent="modal.selectedList = assigneeList"
            >
              <user-avatar-image :src="assigneeList.avatar" />
              {{ assigneeList.title }}
            </gl-dropdown-item>
          </li>
        </ul>
      </section>
      <gl-dropdown-divider />
      <section>
        <gl-dropdown-header>{{ __('Milestone') }}</gl-dropdown-header>
        <ul>
          <li v-for="(list, i) in milestoneLists" :key="i">
            <gl-dropdown-item
              :class="{ 'is-active': list.id == selected.id }"
              @click.prevent="modal.selectedList = list"
            >
              
              {{ list.title }}
            </gl-dropdown-item>
          </li>
        </ul>
      </section>
    </gl-dropdown>
  </div>
</template>
