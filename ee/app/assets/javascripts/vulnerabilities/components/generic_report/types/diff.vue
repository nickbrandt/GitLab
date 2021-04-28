<script>
import { GlButtonGroup, GlButton } from '@gitlab/ui';
import { VIEW_TYPES } from './constants';
import { createDiffData } from './diff_utils';

export default {
  components: {
    GlButtonGroup,
    GlButton,
  },
  props: {
    before: {
      type: String,
      required: true,
    },
    after: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      view: VIEW_TYPES.DIFF,
    };
  },
  viewTypes: {
    DIFF: VIEW_TYPES.DIFF,
  },
  computed: {
    diffData() {
      return createDiffData(this.before, this.after);
    },
    visibleDiffData() {
      return this.diffData.filter(this.shouldShowLine);
    },
    isDiffView() {
      return this.view === VIEW_TYPES.DIFF;
    },
    isBeforeView() {
      return this.view === VIEW_TYPES.BEFORE;
    },
    isAfterView() {
      return this.view === VIEW_TYPES.AFTER;
    },
  },
  methods: {
    shouldShowLine(line) {
      return (
        this.view === VIEW_TYPES.DIFF ||
        line.type === 'normal' ||
        (line.type === 'removed' && this.view === VIEW_TYPES.BEFORE) ||
        (line.type === 'added' && this.view === VIEW_TYPES.AFTER)
      );
    },
    changeClass(change) {
      return {
        normal: '',
        added: 'new',
        removed: 'old',
      }[change.type];
    },
    changeClassIDiff(action) {
      if (action.removed || action.added) {
        return 'idiff';
      }
      return '';
    },
    setDiffViewType() {
      this.view = VIEW_TYPES.DIFF;
    },
    setBeforeViewType() {
      this.view = VIEW_TYPES.BEFORE;
    },
    setAfterViewType() {
      this.view = VIEW_TYPES.AFTER;
    },
  },
  userColorScheme: window.gon.user_color_scheme,
};
</script>

<template>
  <div class="gl-rounded-base gl-border-solid gl-border-1 gl-border-gray-100">
    <div class="gl-overflow-hidden gl-border-b-solid gl-border-b-1 gl-border-b-gray-100 gl-p-3">
      <gl-button-group class="gl-display-flex gl-float-right">
        <gl-button
          :class="{ selected: isDiffView }"
          :data-view-type="$options.viewTypes.DIFF"
          @click="setDiffViewType"
        >
          {{ s__('GenericReport|Diff') }}
        </gl-button>
        <gl-button
          :class="{ selected: isBeforeView }"
          :data-view-type="$options.viewTypes.DIFF"
          @click="setBeforeViewType"
        >
          {{ s__('GenericReport|Before') }}
        </gl-button>
        <gl-button
          :class="{ selected: isAfterView }"
          :data-view-type="$options.viewTypes.DIFF"
          @click="setAfterViewType"
        >
          {{ s__('Genericreport|After') }}
        </gl-button>
      </gl-button-group>
    </div>
    <table class="code" :class="$options.userColorScheme">
      <tr
        v-for="(line, idx) in visibleDiffData"
        :key="idx"
        :class="changeClass(line)"
        class="line_holder"
      >
        <td class="diff-line-num old_line gl-border-t-0 gl-border-b-0" :class="changeClass(line)">
          {{ line.old_line }}
        </td>
        <td class="diff-line-num new_line gl-border-t-0 gl-border-b-0" :class="changeClass(line)">
          {{ line.new_line }}
        </td>
        <td class="line_content" :class="changeClass(line)">
          <span
            v-for="(action, actionIdx) in line.actions"
            :key="actionIdx"
            class="left right"
            :class="changeClassIDiff(action)"
            >{{ action.value }}</span
          >
        </td>
      </tr>
    </table>
  </div>
</template>
