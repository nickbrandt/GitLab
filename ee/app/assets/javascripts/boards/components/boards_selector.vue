<script>
import $ from 'jquery';
import { throttle } from 'underscore';
import { GlLoadingIcon } from '@gitlab/ui';
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
      open: false,
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
    };
  },
  computed: {
    currentPage() {
      return this.state.currentPage;
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
    toggleDropdown() {
      this.open = !this.open;
    },
    loadBoards(toggleDropdown = true) {
      if (toggleDropdown) {
        this.toggleDropdown();
      }

      if (this.open && !this.boards.length) {
        gl.boardService
          .allBoards()
          .then(res => res.data)
          .then(json => {
            this.loading = false;
            this.boards = json;
          })
          .then(() => this.$nextTick()) // Wait for boards list in DOM
          .then(this.setScrollFade)
          .catch(() => {
            this.loading = false;
          });
      }
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
      <div class="dropdown">
        <button
          class="dropdown-menu-toggle js-dropdown-toggle"
          type="button"
          data-toggle="dropdown"
          @click="loadBoards"
        >
          {{ board.name }} <icon name="chevron-down" />
        </button>
        <div class="dropdown-menu" :class="{ 'is-loading': loading }">
          <div class="dropdown-content-faded-mask js-scroll-fade" :class="scrollFadeClass">
            <ul
              v-if="!loading"
              ref="content"
              class="dropdown-list js-dropdown-list"
              @scroll.passive="throttledSetScrollFade"
            >
              <li v-for="otherBoard in boards" :key="otherBoard.id" class="js-dropdown-item">
                <a :href="`${boardBaseUrl}/${otherBoard.id}`"> {{ otherBoard.name }} </a>
              </li>
              <li v-if="hasMissingBoards" class="small unclickable">
                {{
                  s__(
                    'IssueBoards|Some of your boards are hidden, activate a license to see them again.',
                  )
                }}
              </li>
            </ul>
          </div>

          <gl-loading-icon v-if="loading" class="dropdown-loading" />

          <div v-if="canAdminBoard" class="dropdown-footer">
            <ul class="dropdown-footer-list">
              <li v-if="multipleIssueBoardsAvailable">
                <button type="button" @click.prevent="showPage('new');">
                  {{ s__('IssueBoards|Create new board') }}
                </button>
              </li>
              <li v-if="showDelete">
                <button type="button" class="text-danger" @click.prevent="showPage('delete');">
                  {{ s__('IssueBoards|Delete board') }}
                </button>
              </li>
            </ul>
          </div>
        </div>
      </div>

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
