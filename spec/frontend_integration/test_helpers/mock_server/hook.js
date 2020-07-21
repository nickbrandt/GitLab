import { createAdapter } from '../utils/adapter';
import { createDefaultServer } from './default';

// eslint-disable-next-line import/prefer-default-export
export const useMockServer = () => {
  let server;
  const { adapter, initialize } = createAdapter(() => server);

  beforeEach(() => {
    server = createDefaultServer();
    server.logging = false;

    initialize();
  });

  afterEach(() => {
    server.shutdown();
  });

  return adapter;
};
