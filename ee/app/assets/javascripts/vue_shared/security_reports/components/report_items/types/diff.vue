<script>
import { GlButtonGroup, GlButton } from '@gitlab/ui';
import { createDiffData } from '../diff_utils';

export default {
  name: 'ReportItemDiff',
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
      view: 'diff',
    };
  },
  computed: {
    diffData() {
      debugger;
      return createDiffData(this.before, this.after);
    },
    isDiffView() {
      return this.view === 'diff';
    },
    isBeforeView() {
      return this.view === 'before';
    },
    isAfterView() {
      return this.view === 'after';
    },
  },
  methods: {
    shouldShowLine(line) {
      return (
        this.view === 'diff' ||
        line.type === 'normal' ||
        (line.type === 'removed' && this.view === 'before') ||
        (line.type === 'added' && this.view === 'after')
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
      this.view = 'diff';
    },
    setBeforeViewType() {
      this.view = 'before';
    },
    setAfterViewType() {
      this.view = 'after';
    },
  },
  userColorScheme: window.gon.user_color_scheme,
};
</script>

<template>
  <div class="file-holder rounded border">
    <div class="overflow-hidden border-bottom report-item-diff-header">
      <gl-button-group class="gl-display-flex report-item-diff-buttons float-right">
        <gl-button
          id="inline-diff-btn"
          :class="{ selected: isDiffView }"
          class="gl-w-half"
          data-view-type="diff"
          @click="setDiffViewType"
        >
          {{ __('Diff') }}
        </gl-button>
        <gl-button
          id="inline-diff-btn"
          :class="{ selected: isBeforeView }"
          class="gl-w-half"
          data-view-type="diff"
          @click="setBeforeViewType"
        >
          {{ __('Before') }}
        </gl-button>
        <gl-button
          id="inline-diff-btn"
          :class="{ selected: isAfterView }"
          class="gl-w-half"
          data-view-type="diff"
          @click="setAfterViewType"
        >
          {{ __('After') }}
        </gl-button>
      </gl-button-group>
    </div>
    <table class="code" :class="$options.userColorScheme">
      <tr
        v-for="(line, idx) in diffData"
        v-if="shouldShowLine(line)"
        :key="idx"
        :class="changeClass(line)"
        class="line_holder"
      >
        <td class="diff-line-num old_line border-top-0 border-bottom-0" :class="changeClass(line)">
          {{ line.old_line }}
        </td>
        <td class="diff-line-num new_line border-top-0 border-bottom-0" :class="changeClass(line)">
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
