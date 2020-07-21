import { createDefaultServer } from './index';

if (process.env.NODE_ENV === 'development') {
  window.mockServer = createDefaultServer();
}
