<script>
import { __ } from '~/locale';
import $ from 'jquery';
import _ from 'underscore';
import Icon from '~/vue_shared/components/icon.vue';
import { GlLoadingIcon, GlButton, GlAvatar } from '@gitlab/ui';
import Api from '~/api';
import { getIdenticonBackgroundClass, getIdenticonTitle } from '~/helpers/avatar_helper';

export default {
  name: 'GroupsDropdownFilter',
  components: {
    Icon,
    GlLoadingIcon,
    GlButton,
    GlAvatar,
  },
  data() {
    return {
      loading: true,
      selectedGroup: {},
    };
  },
  computed: {
    selectedGroupName() {
      return this.selectedGroup.name || __('Choose a group');
    },
  },
  mounted() {
    $(this.$refs.groupsDropdown).glDropdown({
      selectable: true,
      filterable: true,
      filterRemote: true,
      fieldName: 'group_id',
      search: {
        fields: ['full_name'],
      },
      clicked: this.onClick,
      data: this.fetchData,
      renderRow: group => this.rowTemplate(group),
      text: group => group.name,
      opened: e => e.target.querySelector('.dropdown-input-field').focus(),
    });
  },
  methods: {
    onClick({ $el, e }) {
      e.preventDefault();
      this.selectedGroup = {
        id: $el.data('id'),
        name: $el.data('name'),
        path: $el.data('path'),
        avatar_url: $el.data('avatar-url'),
      };
      this.$emit('selected', this.selectedGroup);
    },
    fetchData(term, callback) {
      this.loading = true;
      return Api.groups(term, {}, groups => {
        this.loading = false;
        callback(groups);
      });
    },
    rowTemplate(group) {
      return `
            <li>
              <a href='#' class='dropdown-menu-link' data-id="${group.id}" data-name="${_.escape(
        group.name,
      )}" data-path="${group.path}" data-avatar-url="${group.avatar_url}">
              ${this.avatarTemplate(group)}
              <div class="align-middle">${_.escape(group.name)}</div>
              </a>
            </li>
          `;
    },
    avatarTemplate(group) {
      return group.avatar_url !== null
        ? `<img src="${group.avatar_url}" alt="${this.groupAvatarAltText}" class="avatar rect-avatar s16"/>`
        : `<div class="avatar identicon s16 rect-avatar d-flex justify-content-center flex-column ${getIdenticonBackgroundClass(
            group.id,
          )}">${getIdenticonTitle(group.name)}</div>`;
    },
  },
};
</script>

<template>
  <div>
    <div ref="groupsDropdown" class="dropdown dropdown-groups">
      <gl-button
        class="dropdown-menu-toggle wide shadow-none bg-white"
        type="button"
        data-toggle="dropdown"
        aria-expanded="false"
        :aria-label="selectedGroupName"
      >
        <gl-avatar
          v-if="selectedGroup.name"
          :src="selectedGroup.avatar_url"
          :entity-id="selectedGroup.id"
          :entity-name="selectedGroup.name"
          :size="16"
          shape="rect"
          :alt="s__('CycleAnalytics|group avatar')"
          class="prepend-top-2"
        />
        {{ selectedGroupName }}
        <icon name="chevron-down" />
      </gl-button>
      <div class="dropdown-menu dropdown-menu-selectable dropdown-menu-full-width">
        <div class="dropdown-title">{{ __('Groups') }}</div>
        <div class="dropdown-input">
          <input class="dropdown-input-field" type="search" :placeholder="__('Search groups')" />
          <icon name="search" class="dropdown-input-search" data-hidden="true" />
        </div>
        <div class="dropdown-content"></div>
        <gl-loading-icon class="dropdown-loading" />
      </div>
    </div>
  </div>
</template>
