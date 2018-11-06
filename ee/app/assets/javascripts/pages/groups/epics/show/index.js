import ZenMode from '~/zen_mode';
import initEpicShow from 'ee/epics/epic_show/epic_show_bundle';
import ShortcutsEpic from 'ee/behaviors/shortcuts/shortcuts_epic';
import '~/notes/index';

document.addEventListener('DOMContentLoaded', () => {
  new ZenMode(); // eslint-disable-line no-new
  initEpicShow();
  new ShortcutsEpic(); // eslint-disable-line no-new
});
