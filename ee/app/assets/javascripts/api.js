import Api from '~/api';
import axios from '~/lib/utils/axios_utils';

export default {
  ...Api,
  geoNodesPath: '/api/:version/geo_nodes',
  ldapGroupsPath: '/api/:version/ldap/:provider/groups.json',
  subscriptionPath: '/api/:version/namespaces/:id/gitlab_subscription',
  childEpicPath: '/api/:version/groups/:id/epics/:epic_iid/epics',
  groupEpicsPath:
    '/api/:version/groups/:id/epics?include_ancestor_groups=:includeAncestorGroups&include_descendant_groups=:includeDescendantGroups',
  epicIssuePath: '/api/:version/groups/:id/epics/:epic_iid/issues/:issue_id',

  userSubscription(namespaceId) {
    const url = Api.buildUrl(this.subscriptionPath).replace(':id', encodeURIComponent(namespaceId));

    return axios.get(url);
  },

  ldapGroups(query, provider, callback) {
    const url = Api.buildUrl(this.ldapGroupsPath).replace(':provider', provider);
    return axios
      .get(url, {
        params: {
          search: query,
          per_page: 20,
          active: true,
        },
      })
      .then(({ data }) => {
        callback(data);

        return data;
      });
  },

  createChildEpic({ groupId, parentEpicIid, title }) {
    const url = Api.buildUrl(this.childEpicPath)
      .replace(':id', groupId)
      .replace(':epic_iid', parentEpicIid);

    return axios.post(url, {
      title,
    });
  },

  groupEpics({ groupId, includeAncestorGroups = false, includeDescendantGroups = true }) {
    const url = Api.buildUrl(this.groupEpicsPath)
      .replace(':id', groupId)
      .replace(':includeAncestorGroups', includeAncestorGroups)
      .replace(':includeDescendantGroups', includeDescendantGroups);

    return axios.get(url);
  },

  addEpicIssue({ groupId, epicIid, issueId }) {
    const url = Api.buildUrl(this.epicIssuePath)
      .replace(':id', groupId)
      .replace(':epic_iid', epicIid)
      .replace(':issue_id', issueId);

    return axios.post(url);
  },

  removeEpicIssue({ groupId, epicIid, epicIssueId }) {
    const url = Api.buildUrl(this.epicIssuePath)
      .replace(':id', groupId)
      .replace(':epic_iid', epicIid)
      .replace(':issue_id', epicIssueId);

    return axios.delete(url);
  },
};
