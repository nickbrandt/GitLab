/* eslint-disable no-var, func-names, one-var, no-else-return */

import $ from 'jquery';
import Api from '~/api';
import { sprintf, __ } from '~/locale';

function AdminEmailSelect() {
  import(/* webpackChunkName: 'select2' */ 'select2/select2')
    .then(() => {
      $('.ajax-admin-email-select').each(
        (function(_this) {
          return function(i, select) {
            return $(select).select2({
              placeholder: __('Select group or project'),
              multiple: $(select).hasClass('multiselect'),
              minimumInputLength: 0,
              query(query) {
                const groupsFetch = Api.groups(query.term, {});
                const projectsFetch = Api.projects(query.term, {
                  order_by: 'id',
                  membership: false,
                });
                return Promise.all([projectsFetch, groupsFetch]).then(([projects, groups]) => {
                  var all, data;
                  all = {
                    id: 'all',
                  };
                  data = [all].concat(groups, projects);
                  return query.callback({
                    results: data,
                  });
                });
              },
              id(object) {
                if (object.path_with_namespace) {
                  return `project-${object.id}`;
                } else if (object.path) {
                  return `group-${object.id}`;
                } else {
                  return 'all';
                }
              },
              formatResult(...args) {
                return _this.formatResult(...args);
              },
              formatSelection(...args) {
                return _this.formatSelection(...args);
              },
              dropdownCssClass: 'ajax-admin-email-dropdown',
              escapeMarkup(m) {
                return m;
              },
            });
          };
        })(this),
      );
    })
    .catch(() => {});
}

AdminEmailSelect.prototype.formatResult = function(object) {
  if (object.path_with_namespace) {
    return `<div class='project-result'> <div class='project-name'>${object.name}</div> <div class='project-path'>${object.path_with_namespace}</div> </div>`;
  } else if (object.path) {
    return `<div class='group-result'> <div class='group-name'>${object.name}</div> <div class='group-path'>${object.path}</div> </div>`;
  } else {
    return `<div class='group-result'> <div class='group-name'>${__(
      'All',
    )}</div> <div class='group-path'>${__('All groups and projects')}</div> </div>`;
  }
};

AdminEmailSelect.prototype.formatSelection = function(object) {
  if (object.path_with_namespace) {
    return sprintf(__('Project: %{name}'), { name: object.name });
  } else if (object.path) {
    return sprintf(__('Group: %{name}'), { name: object.name });
  } else {
    return __('All groups and projects');
  }
};

export default AdminEmailSelect;
