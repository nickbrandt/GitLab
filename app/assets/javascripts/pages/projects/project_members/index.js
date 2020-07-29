import Vue from 'vue';
import Members from 'ee_else_ce/members';
import memberExpirationDate from '~/member_expiration_date';
import UsersSelect from '~/users_select';
import groupsSelect from '~/groups_select';
import RemoveMemberModal from '~/vue_shared/components/remove_member_modal.vue';
import memberDatePicker from './components/member_date_picker.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

const mountVueDatePicker = el => {
  const props = {
    ...el.dataset,
    disabled: parseBoolean(el.dataset.disabled),
    value: new Date(el.dataset.value),
  };

  return new Vue({
    el,
    render(h) {
      return h(memberDatePicker, { props });
    },
  });
};

function mountRemoveMemberModal() {
  const el = document.querySelector('.js-remove-member-modal');
  if (!el) {
    return false;
  }

  return new Vue({
    el,
    render(createComponent) {
      return createComponent(RemoveMemberModal);
    },
  });
}

document.addEventListener('DOMContentLoaded', () => {
  groupsSelect();
  memberExpirationDate();
  memberExpirationDate('.js-access-expiration-date-groups');
  mountRemoveMemberModal();
  [...document.querySelectorAll('.js-vue-member-date-picker')].map(mountVueDatePicker);

  new Members(); // eslint-disable-line no-new
  new UsersSelect(); // eslint-disable-line no-new
});
