import * as Sentry from '@sentry/browser';
import Visibility from 'visibilityjs';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { unwrapStagesWithNeeds } from '../unwrapping_utils';

const addMulti = (mainPipelineProjectPath, linkedPipeline) => {
  return {
    ...linkedPipeline,
    multiproject: mainPipelineProjectPath !== linkedPipeline.project.fullPath,
  };
};

/* eslint-disable @gitlab/require-i18n-strings */
const getQueryHeaders = (etagResource) => {
  return {
    fetchOptions: {
      method: 'GET',
    },
    headers: {
      'X-GITLAB-GRAPHQL-FEATURE-CORRELATION': 'verify/ci/pipeline-graph',
      'X-GITLAB-GRAPHQL-RESOURCE-ETAG': etagResource,
      'X-REQUESTED_WITH': 'XMLHttpRequest',
    },
  };
};

const reportToSentry = (component, failureType) => {
  Sentry.withScope((scope) => {
    scope.setTag('component', component);
    Sentry.captureException(failureType);
  });
};

const serializeGqlErr = (gqlError) => {
  if (!gqlError) {
    return 'gqlError data not available.';
  }

  const { locations, message, path } = gqlError;

  return `
    ${message}.
    Locations: ${locations
      .flatMap((loc) => Object.entries(loc))
      .flat(2)
      .join(' ')}.
    Path: ${path.join(', ')}.
  `;
};

/* eslint-enable @gitlab/require-i18n-strings */

const toggleQueryPollingByVisibility = (queryRef, interval = 10000) => {
  const stopStartQuery = (query) => {
    if (!Visibility.hidden()) {
      query.startPolling(interval);
    } else {
      query.stopPolling();
    }
  };

  stopStartQuery(queryRef);
  Visibility.change(stopStartQuery.bind(null, queryRef));
};

const transformId = (linkedPipeline) => {
  return { ...linkedPipeline, id: getIdFromGraphQLId(linkedPipeline.id) };
};

const unwrapPipelineData = (mainPipelineProjectPath, data) => {
  if (!data?.project?.pipeline) {
    return null;
  }

  const { pipeline } = data.project;

  const {
    upstream,
    downstream,
    stages: { nodes: stages },
  } = pipeline;

  const nodes = unwrapStagesWithNeeds(stages);

  return {
    ...pipeline,
    id: getIdFromGraphQLId(pipeline.id),
    stages: nodes,
    upstream: upstream
      ? [upstream].map(addMulti.bind(null, mainPipelineProjectPath)).map(transformId)
      : [],
    downstream: downstream
      ? downstream.nodes.map(addMulti.bind(null, mainPipelineProjectPath)).map(transformId)
      : [],
  };
};

const validateConfigPaths = (value) => value.graphqlResourceEtag?.length > 0;

export {
  getQueryHeaders,
  reportToSentry,
  serializeGqlErr,
  toggleQueryPollingByVisibility,
  unwrapPipelineData,
  validateConfigPaths,
};
