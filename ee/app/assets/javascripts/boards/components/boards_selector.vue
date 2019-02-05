<script>
import $ from 'jquery';
import { throttle } from 'underscore';
import {
  GlLoadingIcon,
  GlSearchBox,
  GlDropdown,
  GlDropdownDivider,
  GlDropdownHeader,
  GlDropdownItem,
} from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import boardsStore from '~/boards/stores/boards_store';
import BoardForm from './board_form.vue';
import AssigneeList from './assignees_list_slector';
import MilestoneList from './milestone_list_selector';

export default {
  name: 'BoardsSelector',
  components: {
    Icon,
    BoardForm,
    GlLoadingIcon,
    GlSearchBox,
    GlDropdown,
    GlDropdownDivider,
    GlDropdownHeader,
    GlDropdownItem,
  },
  props: {
    currentBoard: {
      type: Object,
      required: true,
    },
    milestonePath: {
      type: String,
      required: true,
    },
    throttleDuration: {
      type: Number,
      default: 200,
    },
    boardBaseUrl: {
      type: String,
      required: true,
    },
    hasMissingBoards: {
      type: Boolean,
      required: true,
    },
    canAdminBoard: {
      type: Boolean,
      required: true,
    },
    multipleIssueBoardsAvailable: {
      type: Boolean,
      required: true,
    },
    labelsPath: {
      type: String,
      required: true,
    },
    projectId: {
      type: Number,
      required: true,
    },
    groupId: {
      type: Number,
      required: true,
    },
    scopedIssueBoardFeatureEnabled: {
      type: Boolean,
      required: true,
    },
    weights: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      loading: true,
      hasScrollFade: false,
      hasAssigneesListMounted: false,
      hasMilestoneListMounted: false,
      scrollFadeInitialized: false,
      boards: [],
      state: boardsStore.state,
      throttledSetScrollFade: throttle(this.setScrollFade, this.throttleDuration),
      contentClientHeight: 0,
      maxPosition: 0,
      store: boardsStore,
      filterTerm: '',
    };
  },
  computed: {
    currentPage() {
      return this.state.currentPage;
    },
    filteredBoards() {
      return this.boards.filter(board =>
        board.name.toLowerCase().includes(this.filterTerm.toLowerCase()),
      );
    },
    reload: {
      get() {
        return this.state.reload;
      },
      set(newValue) {
        this.state.reload = newValue;
      },
    },
    board() {
      return this.state.currentBoard;
    },
    showDelete() {
      return this.boards.length > 1;
    },
    scrollFadeClass() {
      return {
        'fade-out': !this.hasScrollFade,
      };
    },
  },
  watch: {
    filteredBoards() {
      this.scrollFadeInitialized = false;
      this.$nextTick(this.setScrollFade);
    },
    reload() {
      if (this.reload) {
        this.boards = [];
        this.loading = true;
        this.reload = false;

        this.loadBoards(false);
      }
    },
  },
  created() {
    this.state.currentBoard = this.currentBoard;
    boardsStore.state.assignees = [];
    boardsStore.state.milestones = [];
    $('#js-add-list').on('hide.bs.dropdown', this.handleDropdownHide);
    $('.js-new-board-list-tabs').on('click', this.handleDropdownTabClick);
  },
  methods: {
    showPage(page) {
      this.state.reload = false;
      this.state.currentPage = page;
    },
    loadBoards(toggleDropdown = true) {
      if (toggleDropdown && this.boards.length > 0) {
        return;
      }

      gl.boardService
        .allBoards()
        .then(res => res.data)
        .then(json => {
          this.loading = false;
          this.boards = json;
        })
        .then(() => this.$nextTick()) // Wait for boards list in DOM
        .then(() => {
          this.setScrollFade();
        })
        .catch(() => {
          this.loading = false;
        });
    },
    isScrolledUp() {
      const { content } = this.$refs;
      const currentPosition = this.contentClientHeight + content.scrollTop;

      return content && currentPosition < this.maxPosition;
    },
    initScrollFade() {
      this.scrollFadeInitialized = true;

      const { content } = this.$refs;

      this.contentClientHeight = content.clientHeight;
      this.maxPosition = content.scrollHeight;
    },
    setScrollFade() {
      if (!this.scrollFadeInitialized) this.initScrollFade();

      this.hasScrollFade = this.isScrolledUp();
    },
    handleDropdownHide(e) {
      const $currTarget = $(e.currentTarget);
      if ($currTarget.data('preventClose')) {
        e.preventDefault();
      }
      $currTarget.removeData('preventClose');
    },
    handleDropdownTabClick(e) {
      const $addListEl = $('#js-add-list');
      $addListEl.data('preventClose', true);
      if (e.target.dataset.action === 'tab-assignees' && !this.hasAssigneesListMounted) {
        this.assigneeList = AssigneeList();
        this.hasAssigneesListMounted = true;
      }

      if (e.target.dataset.action === 'tab-milestones' && !this.hasMilestoneListMounted) {
        this.milstoneList = MilestoneList();
        this.hasMilestoneListMounted = true;
      }
    },
  },
};
</script>

<template>
  <div class="boards-switcher js-boards-selector append-right-10">
    <span class="boards-selector-wrapper js-boards-selector-wrapper">
      <gl-dropdown
        toggle-class="dropdown-menu-toggle js-dropdown-toggle"
        menu-class="flex-column dropdown-extended-height"
        :text="board.name"
        @show="loadBoards"
      >
        <div>
          <div class="dropdown-title mb-0" @mousedown.prevent>
            {{ s__('IssueBoards|Switch board') }}
          </div>
        </div>

        <gl-dropdown-header class="mt-0">
          <gl-search-box ref="searchBox" v-model="filterTerm" />
        </gl-dropdown-header>

        <div
          v-if="!loading"
          ref="content"
          class="dropdown-content flex-fill"
          @scroll.passive="throttledSetScrollFade"
        >
          <gl-dropdown-item
            v-show="filteredBoards.length === 0"
            class="no-pointer-events text-secondary"
          >
            {{ s__('IssueBoards|No matching boards found') }}
          </gl-dropdown-item>

          <gl-dropdown-item
            v-for="otherBoard in filteredBoards"
            :key="otherBoard.id"
            class="js-dropdown-item"
            :href="`${boardBaseUrl}/${otherBoard.id}`"
          >
            {{ otherBoard.name }}
          </gl-dropdown-item>
          <gl-dropdown-item v-if="hasMissingBoards" class="small unclickable">
            {{
              s__(
                'IssueBoards|Some of your boards are hidden, activate a license to see them again.',
              )
            }}
          </gl-dropdown-item>
        </div>

        <div
          v-show="filteredBoards.length > 0"
          class="dropdown-content-faded-mask"
          :class="scrollFadeClass"
        ></div>

        <gl-loading-icon v-if="loading" class="dropdown-loading" />

        <div v-if="canAdminBoard">
          <gl-dropdown-divider />

          <gl-dropdown-item v-if="multipleIssueBoardsAvailable" @click.prevent="showPage('new')">
            {{ s__('IssueBoards|Create new board') }}
          </gl-dropdown-item>

          <gl-dropdown-item
            v-if="showDelete"
            class="text-danger"
            @click.prevent="showPage('delete')"
          >
            {{ s__('IssueBoards|Delete board') }}
          </gl-dropdown-item>
        </div>
      </gl-dropdown>

      <board-form
        v-if="currentPage"
        :milestone-path="milestonePath"
        :labels-path="labelsPath"
        :project-id="projectId"
        :group-id="groupId"
        :can-admin-board="canAdminBoard"
        :scoped-issue-board-feature-enabled="scopedIssueBoardFeatureEnabled"
        :weights="weights"
      />
    </span>
  </div>
</template>
