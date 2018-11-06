import $ from 'jquery';
import Mousetrap from 'mousetrap';
import Cookies from 'js-cookie';
import ShortcutsIssuable from '~/behaviors/shortcuts/shortcuts_issuable';

export default class ShortcutsEpic extends ShortcutsIssuable {
  constructor() {
    super();

    const $issuableSidebar = $('.js-issuable-update');

    Mousetrap.bind('l', () =>
      ShortcutsEpic.openSidebarDropdown($issuableSidebar.find('.js-labels-block')),
    );
    Mousetrap.bind('r', ShortcutsIssuable.replyWithSelectedText);
    Mousetrap.bind('e', ShortcutsIssuable.editIssue);
  }

  static openSidebarDropdown($block) {
    if (Cookies.get('collapsed_gutter') === 'true') {
      document.dispatchEvent(new Event('toggleSidebarRevealLabelsDropdown'));
    } else {
      $block.find('.js-sidebar-dropdown-toggle').trigger('click');
    }
  }
}
