<script>
import MilestoneSelect from '~/milestone_select';
import { GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';

const ANY_MILESTONE = {
  title: __('Any Milestone'),
  titleClass: 'text-secondary',
  name: 'Any',
  id: null,
};

const NO_MILESTONE = {
  title: __('No Milestone'),
  name: 'None',
  id: -1,
};

const DEFAULT_MILESTONE = {
  title: ANY_MILESTONE.title,
  titleClass: 'bold',
  name: '',
};

function getMilestoneIdFromTitle({ title, id }) {
  switch (title) {
    case ANY_MILESTONE.title:
      return ANY_MILESTONE.id;
    case NO_MILESTONE.title:
      return NO_MILESTONE.id;
    default:
      return id;
  }
}

export default {
  components: {
    GlLoadingIcon,
  },
  props: {
    board: {
      type: Object,
      required: true,
    },
    milestonePath: {
      type: String,
      required: true,
    },
    canEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
  },

  computed: {
    milestone() {
      switch (this.milestoneId) {
        case NO_MILESTONE.id:
          return NO_MILESTONE;
        case ANY_MILESTONE.id:
          return ANY_MILESTONE;
        default:
          return this.board.milestone || DEFAULT_MILESTONE;
      }
    },
    milestoneTitle() {
      return this.milestone.title;
    },
    milestoneId() {
      return this.board.milestone_id;
    },
    milestoneTitleClass() {
      return this.milestone.titleClass || DEFAULT_MILESTONE.titleClass;
    },
    selected() {
      return this.milestone.name;
    },
  },
  mounted() {
    this.milestoneDropdown = new MilestoneSelect(null, this.$refs.dropdownButton, {
      handleClick: this.selectMilestone,
    });
  },
  methods: {
    selectMilestone(milestone) {
      const id = getMilestoneIdFromTitle(milestone);
      this.board.milestone_id = id;
      this.board.milestone = {
        ...milestone,
        id,
      };
    },
  },
};
</script>

<template>
  <div class="block milestone">
    <div class="title append-bottom-10">
      Milestone
      <button v-if="canEdit" type="button" class="edit-link btn btn-blank float-right">Edit</button>
    </div>
    <div :class="milestoneTitleClass" class="value">{{ milestoneTitle }}</div>
    <div class="selectbox" style="display: none;">
      <input :value="milestoneId" name="milestone_id" type="hidden" />
      <div class="dropdown">
        <button
          ref="dropdownButton"
          :data-selected="selected"
          :data-milestones="milestonePath"
          :data-show-no="true"
          :data-show-any="true"
          :data-show-started="true"
          :data-show-upcoming="true"
          :data-use-id="true"
          class="dropdown-menu-toggle wide"
          data-toggle="dropdown"
          type="button"
        >
          Milestone <i aria-hidden="true" data-hidden="true" class="fa fa-chevron-down"> </i>
        </button>
        <div class="dropdown-menu dropdown-select dropdown-menu-selectable">
          <div class="dropdown-input">
            <input
              type="search"
              class="dropdown-input-field"
              placeholder="Search milestones"
              autocomplete="off"
            />
            <i aria-hidden="true" data-hidden="true" class="fa fa-search dropdown-input-search">
            </i>
            <i
              role="button"
              aria-hidden="true"
              data-hidden="true"
              class="fa fa-times dropdown-input-clear js-dropdown-input-clear"
            >
            </i>
          </div>
          <div class="dropdown-content"></div>
          <div class="dropdown-loading"><gl-loading-icon /></div>
        </div>
      </div>
    </div>
  </div>
</template>
