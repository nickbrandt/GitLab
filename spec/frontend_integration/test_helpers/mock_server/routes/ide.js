import { Response } from 'miragejs';

export default server => {
  server.post('*/ide_terminals/check_config', () => {
    return new Response(404);
  });
};
