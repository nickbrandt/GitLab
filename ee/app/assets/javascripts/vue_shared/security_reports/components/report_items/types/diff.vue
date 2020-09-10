<script>
import { GlButtonGroup, GlButton } from '@gitlab/ui';
import { diffChars } from 'diff';

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
      const opts = {
        ignoreWhitespace: false,
        newlineIsToken: true,
      };
      const actions = diffChars(this.before, this.after, opts);
      const lines = [];
      let currLine = { actions: [] };

      while (actions.length > 0) {
        const action = actions.shift();
        const splitActions = this.splitAction(action);
        currLine.actions.push(splitActions[0]);
        if (splitActions.length > 1) {
          lines.push(currLine);
          currLine = { actions: [] };
          splitActions.slice(1).forEach((x) => actions.unshift(x));
        }
      }
      lines.push(currLine);
      return this.splitLinesInline(lines);
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
    splitLinesInline(lines) {
      const res = [];
      lines.forEach((line, idx) => {
        const removed = [];
        const added = [];
        const normal = [];
        line.actions.forEach((action) => {
          if (action.removed) {
            removed.push(action);
          } else if (action.added) {
            added.push(action);
          } else {
            removed.push(action);
            added.push(action);
            normal.push(action);
          }
        });
        if (normal.length === 1) {
          res.push({ type: 'normal', old_line: idx + 1, actions: normal });
          return;
        }
        res.push(...this.createDistinctLines('removed', idx, removed, 'old_line'));
        res.push(...this.createDistinctLines('added', idx, added, 'new_line'));
      });
      return res;
    },
    createDistinctLines(type, startIdx, actions, lineKey) {
      const res = [];
      let currLineNo = startIdx;
      let currLine = null;
      const newLine = () => {
        if (currLine !== null) {
          res.push(currLine);
        }
        currLineNo += 1;
        currLine = { type: type, actions: [] };
        currLine[lineKey] = currLineNo;
      };
      newLine();

      actions.forEach((action) => {
        const splitActions = this.splitAction(action, true);
        currLine.actions.push(splitActions[0]);
        splitActions.slice(1).forEach((splitAction) => {
          newLine();
          currLine.actions.push(splitAction);
        });
      });
      res.push(currLine);

      return res;
    },
    splitAction(action, force) {
      if (action.added && !force) {
        return [action];
      }
      const splitValues = action.value.split('\n');
      const res = [];
      splitValues.forEach((splitValue) => {
        res.push({
          added: action.added,
          removed: action.removed,
          value: splitValue,
        });
      });
      return res;
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
    <div class="overflow-hidden border-bottom p-2">
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
