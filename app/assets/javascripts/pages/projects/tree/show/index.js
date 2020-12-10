// import $ from 'jquery';
import initTree from 'ee_else_ce/repository';
import initBlob from '~/blob_edit/blob_bundle';
// import ShortcutsNavigation from '../../../../behaviors/shortcuts/shortcuts_navigation';
// import NewCommitForm from '../../../../new_commit_form';

// SAM: this can probably be loaded on click or when modal is open (this will shave off around 100ms)
// new NewCommitForm($('.js-create-dir-form')); // eslint-disable-line no-new
initTree();

// SAM: defer loading of this if seen on screen (lazy loading) or when user start scrolling
initBlob();

// SAM: maybe load this on keypress (show shave some time off as well)
// new ShortcutsNavigation(); // eslint-disable-line no-new
