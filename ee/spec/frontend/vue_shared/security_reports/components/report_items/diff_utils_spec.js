import { diffChars } from 'diff';
import {
  groupActionsByLines,
  createDiffData,
} from 'ee/vue_shared/security_reports/components/report_items/diff_utils';

describe('Report Items Diff Utils', () => {
  describe('groupActionsByLines', () => {
    it('Correctly groups single-line changes by lines', () => {
      const before = 'hello world';
      const after = 'HELLO world';

      const actions = diffChars(before, after);
      const lines = groupActionsByLines(actions);
      expect(lines.length).toEqual(1);

      const line = lines[0];
      expect(line.actions.length).toEqual(3);
      expect(line.actions[0].removed).toEqual(true);
      expect(line.actions[0].value).toEqual('hello');

      expect(line.actions[1].added).toEqual(true);
      expect(line.actions[1].value).toEqual('HELLO');

      expect(line.actions[2].added || line.actions[2].removed).toEqual(undefined);
      expect(line.actions[2].value).toEqual(' world');
    });

    it('Correctly groups whole-line deletions by lines', () => {
      const before = 'a\nb';
      const after = 'b';

      const actions = diffChars(before, after);
      const lines = groupActionsByLines(actions);
      expect(lines.length).toEqual(2);

      const line0 = lines[0];
      expect(line0.actions.length).toEqual(1);
      expect(line0.actions[0].removed).toEqual(true);
      expect(line0.actions[0].value).toEqual('a');

      const line1 = lines[1];
      expect(line1.actions.length).toEqual(1);
      expect(line1.actions[0].removed || line1.actions[0].added).toEqual(undefined);
      expect(line1.actions[0].value).toEqual('b');
    });
  });

  describe('createDiffData', () => {
    it('Correctly creates diff lines for single line changes', () => {
      const before = 'hello world';
      const after = 'HELLO world';

      const lines = createDiffData(before, after);
      expect(lines.length).toEqual(2);
      expect(lines[0].type).toEqual('removed');
      expect(lines[0].actions.length).toEqual(2);

      const act00 = lines[0].actions[0];
      expect(act00.removed).toEqual(true);
      expect(act00.value).toEqual('hello');

      const act01 = lines[0].actions[1];
      expect(act01.removed || act01.added).toEqual(undefined);
      expect(act01.value).toEqual(' world');

      const act10 = lines[1].actions[0];
      expect(act10.added).toEqual(true);
      expect(act10.value).toEqual('HELLO');

      const act11 = lines[1].actions[1];
      expect(act11.removed || act01.added).toEqual(undefined);
      expect(act11.value).toEqual(' world');
    });

    it('Correctly creates diff lines for single line deletions', () => {
      const before = 'a\nb';
      const after = 'b';

      const lines = createDiffData(before, after);
      expect(lines.length).toEqual(2);
      expect(lines[0].type).toEqual('removed');
      expect(lines[0].actions.length).toEqual(1);
      expect(lines[0].actions[0].value).toEqual('a');

      expect(lines[1].type).toEqual('normal');
      expect(lines[1].actions.length).toEqual(1);
      expect(lines[1].actions[0].value).toEqual('b');
    });
  });
});
