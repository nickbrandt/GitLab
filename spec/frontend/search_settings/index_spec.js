import initSearch from '~/search_settings';

describe('search_settings/index', () => {
  let onExpand;
  let onCollapse;
  let app;

  beforeEach(() => {
    const searchRoot = document.createElement('div');
    const el = document.createElement('div');

    onExpand = jest.fn();
    onCollapse = jest.fn();

    app = initSearch({ el, searchRoot, sectionSelector: 'section', onExpand, onCollapse });
  });

  afterEach(() => {
    app.$destroy();
  });

  it('calls onExpand function when expand event is emitted', () => {
    const section = { name: 'section' };
    app.$refs.searchSettings.$emit('expand', section);

    expect(onExpand).toHaveBeenCalledWith(section);
  });

  it('calls onCollapse function when collapse event is emitted', () => {
    const section = { name: 'section' };
    app.$refs.searchSettings.$emit('collapse', section);

    expect(onCollapse).toHaveBeenCalledWith(section);
  });
});
