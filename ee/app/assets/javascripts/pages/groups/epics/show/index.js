import ZenMode from '~/zen_mode';
import Cookies from 'js-cookie';
import initEpicShow from 'ee/epics/epic_show/epic_show_bundle';
import ShortcutsEpic from 'ee/behaviors/shortcuts/shortcuts_epic';
import initEpicApp from 'ee/epic/epic_bundle';
import '~/notes/index';
import { parseBoolean } from '~/lib/utils/common_utils';

document.addEventListener('DOMContentLoaded', () => {
  new ZenMode(); // eslint-disable-line no-new
  if (parseBoolean(Cookies.get('load_new_epic_app'))) {
    initEpicApp();
  } else {
    initEpicShow();
    new ShortcutsEpic(); // eslint-disable-line no-new
  }
});
