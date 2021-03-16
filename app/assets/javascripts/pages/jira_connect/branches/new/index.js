import $ from 'jquery';
import Api from '~/api';
import NewBranchForm from '~/new_branch_form';
import projectSelect from '~/project_select';

function loadBranches(projectId) {
  return Api.branches(projectId, '', { per_page: 500 }).then(({ data }) => {
    let defaultBranch = '';

    const branches = data.map((branch) => {
      if (branch.default) {
        defaultBranch = branch.name;
      }

      return branch.name;
    });

    const dropdown = $('.js-branch-select').data('deprecatedJQueryDropdown');

    dropdown.fullData = branches;
    dropdown.updateLabel(defaultBranch);
    $('#source_branch').val(defaultBranch);
  });
}

document.addEventListener('DOMContentLoaded', () => {
  projectSelect();

  // eslint-disable-next-line no-new
  new NewBranchForm($('.js-create-branch-form'), []);

  const projectId = document.getElementById('project_id');
  projectId.onchange = () => {
    loadBranches(projectId.value);
  };

  if (projectId.value) {
    loadBranches(projectId.value);
  }
});
