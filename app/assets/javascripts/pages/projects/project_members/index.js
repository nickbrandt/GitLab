import Vue from 'vue';
import Members from 'ee_else_ce/members';
import memberExpirationDate from '~/member_expiration_date';
import UsersSelect from '~/users_select';
import groupsSelect from '~/groups_select';
import RemoveMemberModal from '~/vue_shared/components/remove_member_modal.vue';
import MemberExpirationInput from './components/member_expiration_input.vue';

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

function mountDatePicker() {
  const memberInputs = document.querySelectorAll('.js-member-expiration-date-input');
  memberInputs.forEach(el => {
    return new Vue({
      el,
      render(createComponent) {
        return createComponent(MemberExpirationInput, {
          props: { ...el.dataset },
        });
      },
    });
  });
}

document.addEventListener('DOMContentLoaded', () => {
  groupsSelect();
  memberExpirationDate();
  memberExpirationDate('.js-access-expiration-date-groups');
  mountRemoveMemberModal();
  mountDatePicker();

  new Members(); // eslint-disable-line no-new
  new UsersSelect(); // eslint-disable-line no-new
});
