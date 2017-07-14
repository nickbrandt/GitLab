import { template } from 'underscore';
import Api from './api';

const approverItemTemplate = template(`
  <li class="<%- itemClass %> settings-flex-row js-<%- itemClass %>" data-id="<%- id %>">
    <div class="span">
      <% if (isGroup) { %>
        <span class="light">Group:</span>
      <% } %>
      <a href="<%- link %>"><%- name %></a>
      <% if (isGroup) { %>
        <span class="badge"><%- count %></span>
      <% } %>
    </div>
    <div class="pull-right">
      <button class="btn btn-remove js-approver-remove" data-confirm="Are you sure you want to remove <%- type %> <%- name %>?" href="<%- removeLink %>" title="Remove <%- type %>">
        <i aria-hidden="true" data-hidden="true" class="fa fa-trash"></i>
      </button>
    </div>
  </li>
`);

export default class ApproversSelect {
  constructor(page) {
    this.$approverSelect = $('.js-select-user-and-group');
    this.$approversListContainer = $('.js-current-approvers');
    this.$approversList = $('.approver-list', this.$approversListContainer);

    const name = this.$approverSelect.data('name');
    this.fieldNames = [`${name}[approver_ids]`, `${name}[approver_group_ids]`];

    this.approversField = $(`input[name="${this.fieldNames[0]}"]`);
    this.approverGroupsField = $(`input[name="${this.fieldNames[1]}"]`);
    this.$loadWrapper = $('.load-wrapper');

    this.isMR = name === 'merge_request';
    this.isNewMR = this.isMR && page === 'projects:merge_requests:new';

    this.bindEvents();
    this.addEvents();
    this.initSelect2();
  }

  bindEvents() {
    this.handleSelectChange = this.handleSelectChange.bind(this);
    this.fetchGroups = this.fetchGroups.bind(this);
    this.fetchUsers = this.fetchUsers.bind(this);
  }

  addEvents() {
    $(document).on('click', '.js-add-approvers', () => this.addApprover());
    $(document).on('click', '.js-approver-remove', e => this.removeApprover(e));
  }

  static getApprovers(fieldName, approverList) {
    const input = $(`[name="${fieldName}"]`);
    const existingApprovers = $(approverList).map((i, el) =>
      parseInt($(el).data('id'), 10),
    );
    const selectedApprovers = input.val()
      .split(',')
      .filter(val => val !== '');
    return [...existingApprovers, ...selectedApprovers];
  }

  fetchGroups(term) {
    const options = {
      skip_groups: ApproversSelect.getApprovers(this.fieldNames[1], '.js-approver-group'),
    };
    return Api.groups(term, options);
  }

  fetchUsers(term) {
    const options = {
      skip_users: ApproversSelect.getApprovers(this.fieldNames[0], '.js-approver'),
      project_id: $('#project_id').val(),
      merge_request_id: $('#merge_request_id').val(),
      approvers: true,
    };
    return Api.approverUsers(term, options);
  }

  handleSelectChange(e) {
    const { added, removed } = e;
    const userInput = this.approversField;
    const groupInput = this.approverGroupsField;

    if (added) {
      if (added.full_name) {
        groupInput.val(`${groupInput.val()},${added.id}`.replace(/^,/, ''));
      } else {
        userInput.val(`${userInput.val()},${added.id}`.replace(/^,/, ''));
      }
    }

    if (removed) {
      if (removed.full_name) {
        groupInput.val(groupInput.val().replace(new RegExp(`,?${removed.id}`), ''));
      } else {
        userInput.val(userInput.val().replace(new RegExp(`,?${removed.id}`), ''));
      }
    }
  }

  initSelect2() {
    this.$approverSelect.select2({
      placeholder: 'Search for users or groups',
      multiple: true,
      minimumInputLength: 0,
      query: (query) => {
        const fetchGroups = this.fetchGroups(query.term);
        const fetchUsers = this.fetchUsers(query.term);
        return $.when(fetchGroups, fetchUsers).then((groups, users) => {
          const data = {
            results: groups[0].concat(users[0]),
          };
          return query.callback(data);
        });
      },
      formatResult: ApproversSelect.formatResult,
      formatSelection: ApproversSelect.formatSelection,
      containerCssClass: 'js-approvers-input-container',
      dropdownCss() {
        const $input = $('.js-select-user-and-group .select2-input');
        const offset = $input.offset();
        const inputRightPosition = offset.left + $input.outerWidth();
        const $dropdown = $('.select2-drop-active');

        let left = offset.left;
        if ($dropdown.outerWidth() > $input.outerWidth()) {
          left = `${inputRightPosition - $dropdown.width()}px`;
        }
        return {
          left,
          right: 'auto',
          width: 'auto',
        };
      },
    })
    .on('change', this.handleSelectChange);

    this.$approversInputContainer = $('.js-approvers-input-container');
  }

  static formatSelection(approver) {
    const type = Object.hasOwnProperty.call(approver, 'username') ? 'user' : 'group';

    return `
      <div
        class="approver-${type}"
        data-id="${approver.id}"
        data-link="/${approver.full_path}"
        data-name="${approver.full_name || approver.name}"
        data-count="${approver.user_count}"
        data-remove-link="${approver.remove_approver_path}"
      >
        ${approver.full_name || approver.name}
      </div>
    `;
  }

  static formatResult({
    name,
    username,
    avatar_url: avatarUrl,
    full_name: fullName,
    full_path: fullPath,
  }) {
    if (username) {
      const avatar = avatarUrl || gon.default_avatar_url;
      return `
        <div class="user-result">
          <div class="user-image">
            <img class="avatar s40" src="${avatar}">
          </div>
          <div class="user-info">
            <div class="user-name">${name}</div>
            <div class="user-username">@${username}</div>
          </div>
        </div>
      `;
    }

    return `
      <div class="group-result">
        <div class="group-name">${fullName}</div>
        <div class="group-path">${fullPath}</div>
      </div>
    `;
  }

  addApprover() {
    this.fieldNames.forEach(this.saveApprovers.bind(this));
  }

  saveApprovers(fieldName) {
    const $input = window.$(`[name="${fieldName}"]`);
    const newValue = $input.val();
    const $loadWrapper = $('.load-wrapper');
    const $approverSelect = $('.js-select-user-and-group');

    if (!newValue) return undefined;

    if (this.isNewMR) return this.addMergeApprover($input);

    const $form = $('.js-add-approvers').closest('form');
    $loadWrapper.removeClass('hidden');

    return window.$.ajax({
      url: $form.attr('action'),
      type: 'POST',
      data: {
        _method: 'PATCH',
        [fieldName]: newValue,
      },
      success: this.isMR ? this.addMergeApprover.bind(this, $input) : this.updateProjectList,
      complete() {
        $input.val('');
        $approverSelect.select2('val', '');
        $loadWrapper.addClass('hidden');
      },
      error() {
        window.Flash('Failed to add Approver', 'alert');
      },
    });
  }

  removeApprover(e) {
    e.preventDefault();

    const target = e.currentTarget;

    if (this.isNewMR) return this.removeMergeApprover(target);

    const $loadWrapper = $('.load-wrapper');
    $loadWrapper.removeClass('hidden');

    return $.ajax({
      url: target.getAttribute('href'),
      type: 'POST',
      data: {
        _method: 'DELETE',
      },
      success: this.isMR ? this.removeMergeApprover.bind(this, target) : this.updateProjectList,
      complete: () => $loadWrapper.addClass('hidden'),
      error() {
        window.Flash('Failed to remove Approver', 'alert');
      },
    });
  }

  updateProjectList(html) {
    const newHtml = $('.js-current-approvers', html).html();

    this.$approversListContainer.html(newHtml);
  }

  addMergeApprover($input) {
    const ids = $input.val().split(',');
    const isGroup = $input.attr('name').contains('approver_group');
    const selector = isGroup ? '.approver-group' : '.approver-user';

    $(selector, this.$approversInputContainer).forEach((approver) => {
      const approverItem = approverItemTemplate({
        id: approver.data('id'),
        link: approver.data('link'),
        name: approver.data('name'),
        count: approver.data('count'),
        removeLink: approver.data('remove-link'),
        type: isGroup ? 'group' : 'user',
        itemClass: isGroup ? 'approver-group' : 'approver',
        isGroup,
      });

      this.$approversList.append(approverItem);
    });

    this.$approverSelect.select2('val', '');
  }

  removeMergeApprover(target) {
    const approver = $(target).closest('.approver-list li');
    const approverID = approver.data('id');
    const field = approver.hasClass('approver') ? this.approversField : this.approverGroupsField;

    const ids = field.val().split(',');
    const approverIndex = ids.indexOf(approverID);

    if (approverIndex !== -1) ids.splice(approverIndex, 1);
    field.val(ids.join(','));
    approver.remove();
  }
}
