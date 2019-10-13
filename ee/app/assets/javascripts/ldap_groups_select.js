/* eslint-disable no-var, one-var, consistent-return, func-names */

import $ from 'jquery';
import Api from 'ee/api';
import { __ } from '~/locale';

export default function initLDAPGroupsSelect() {
  var groupFormatSelection, ldapGroupResult;
  ldapGroupResult = function(group) {
    return group.cn;
  };
  groupFormatSelection = function(group) {
    return group.cn;
  };
  import(/* webpackChunkName: 'select2' */ 'select2/select2')
    .then(() => {
      $('.ajax-ldap-groups-select').each((i, select) => {
        $(select).select2({
          id(group) {
            return group.cn;
          },
          placeholder: __('Search for a LDAP group'),
          minimumInputLength: 1,
          query(query) {
            var provider;
            provider = $('#ldap_group_link_provider').val();
            return Api.ldapGroups(query.term, provider, groups => {
              var data;
              data = {
                results: groups,
              };
              return query.callback(data);
            });
          },
          initSelection(element, callback) {
            var id;
            id = $(element).val();
            if (id !== '') {
              return callback({
                cn: id,
              });
            }
          },
          formatResult: ldapGroupResult,
          formatSelection: groupFormatSelection,
          dropdownCssClass: 'ajax-groups-dropdown',
          formatNoMatches() {
            return __('Match not found; try refining your search query.');
          },
        });
      });
    })
    .catch(() => {});

  $('#ldap_group_link_provider').on('change', () => {
    $('.ajax-ldap-groups-select').select2('data', null);
  });
}
