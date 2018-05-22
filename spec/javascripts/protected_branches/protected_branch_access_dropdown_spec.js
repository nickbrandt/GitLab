import ProtectedBranchAccessDropdown from 'ee/protected_branches/protected_branch_access_dropdown';

describe('ProtectedBranchAccessDropdown', () => {
  const defaultLabel = 'dummy default label';
  let dropdown;

  beforeEach(() => {
    setFixtures(`
        <div id="dummy-dropdown">
          <span class="dropdown-toggle-text"></span>
        </div>
      `);
    const $dropdown = $('#dummy-dropdown');
    $dropdown.data('defaultLabel', defaultLabel);
    const options = {
      $dropdown,
      accessLevelsData: {
        roles: [
          {
            id: 42,
            text: 'Dummy Role',
          },
        ],
      },
    };
    dropdown = new ProtectedBranchAccessDropdown(options);
  });

  describe('userRowHtml', () => {
    it('escapes users name', () => {
      const user = {
        avatar_url: '',
        name: '<img src=x onerror=alert(document.domain)>',
        username: 'test',
      };
      const template = dropdown.userRowHtml(user);

      expect(template).not.toContain(user.name);
    });
  });
});
