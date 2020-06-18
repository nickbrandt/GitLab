import { normalizeData } from 'ee_else_ce/repository/utils/commit';
import axios from '~/lib/utils/axios_utils';
import getCommits from './queries/getCommits.query.graphql';
import getProjectPath from './queries/getProjectPath.query.graphql';
import getRef from './queries/getRef.query.graphql';

let fetchpromise;
let resolvers = [];

export function resolveCommit(commits, path, { resolve, entry }) {
  const commit = commits.find(c => c.filePath === `${path}/${entry.name}` && c.type === entry.type);

  if (commit) {
    resolve(commit);
  }
}

export function fetchLogsTree(client, path, offset, resolver = null) {
  if (resolver) {
    resolvers.push(resolver);
  }

  if (fetchpromise) return fetchpromise;

  const { projectPath } = client.readQuery({ query: getProjectPath });
  const { escapedRef } = client.readQuery({ query: getRef });

  const apiUrl = `${
    gon.relative_url_root
  }/${projectPath}/-/refs/${escapedRef}/logs_tree/${encodeURIComponent(path.replace(/^\//, ''))}`;

  const parseLogsTreeResult = (data, headers) => {
    const headerLogsOffset = headers['more-logs-offset'];
    const { commits } = client.readQuery({ query: getCommits });
    const newCommitData = [...commits, ...normalizeData(data, path)];
    client.writeQuery({
      query: getCommits,
      data: { commits: newCommitData },
    });

    resolvers.forEach(r => resolveCommit(newCommitData, path, r));

    fetchpromise = null;

    if (headerLogsOffset) {
      fetchLogsTree(client, path, headerLogsOffset);
    } else {
      resolvers = [];
    }
  };

  // Checking if the startup call was already fired (Hacky URL Setup right now)
  if (offset === '0' && gl?.startup_calls[`${apiUrl}?format=json&offset=0`]) {
    fetchpromise = gl.startup_calls[`${apiUrl}?format=json&offset=0`].fetchCall;
    let headers;
    return fetchpromise
      .then(response => {
        headers = response.headers;
        return response.json();
      })
      .then(data => {
        parseLogsTreeResult(data, headers);
      });
  }

  fetchpromise = axios
    .get(apiUrl, {
      params: { format: 'json', offset },
    })
    .then(({ data, headers }) => parseLogsTreeResult(data, headers));

  return fetchpromise;
}
