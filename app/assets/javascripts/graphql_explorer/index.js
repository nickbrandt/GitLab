import GraphiQL from 'graphiql';
import React from 'react';
import { render } from 'react-dom';

const target = document.getElementById('graphiql');

function graphQLFetcher(graphQLParams) {
  return fetch(target.dataset.graphqlPath, {
    method: 'post',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(graphQLParams),
    credentials: 'omit',
  }).then((response) => {
    // eslint-disable-next-line promise/no-nesting
    return response.json().catch(() => response.text());
  });
}

render(
  React.createElement(GraphiQL, {
    fetcher: graphQLFetcher,
    defaultVariableEditorOpen: true,
  }),
  target,
);
