import createComponent from 'spec/boards/board_list_common_spec';

describe('BoardList Component', () => {
  let mock;
  let component;

  beforeEach(done => {
    const listIssueProps = {
      project: {
        path: '/test',
      },
    };

    const componentProps = {
      groupId: undefined,
      issueLinkBase: '/test/:project_path/issues',
    };

    ({ mock, component } = createComponent({
      done,
      componentProps,
      listIssueProps,
    }));
  });

  afterEach(() => {
    mock.restore();
  });

  it('renders link properly in issue', () => {
    expect(
      component.$el.querySelector('.board-card .board-card-title a').getAttribute('href'),
    ).not.toContain(':project_path');
  });
});
