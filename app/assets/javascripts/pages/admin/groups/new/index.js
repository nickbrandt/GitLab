import BindInOut from '../../../../behaviors/bind_in_out';
import Group from '../../../../group';
import initAvatarPicker from '~/avatar_picker';

document.addEventListener('DOMContentLoaded', () => {
  BindInOut.initAll();
  initAvatarPicker();

  return new Group();
});
