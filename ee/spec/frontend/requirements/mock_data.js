export const mockUserPermissions = {
  updateRequirement: true,
  adminRequirement: true,
};

export const mockAuthor = {
  name: 'Administrator',
  username: 'root',
  avatarUrl: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
  webUrl: 'http://0.0.0.0:3000/root',
};

export const requirement1 = {
  iid: '1',
  title: 'Virtutis, magnitudinis animi, patientiae, fortitudinis fomentis dolor mitigari solet.',
  createdAt: '2020-03-19T08:09:09Z',
  updatedAt: '2020-03-20T08:09:09Z',
  state: 'OPENED',
  userPermissions: mockUserPermissions,
  author: mockAuthor,
};

export const requirement2 = {
  iid: '2',
  title: 'Est autem officium, quod ita factum est, ut eius facti probabilis ratio reddi possit.',
  createdAt: '2020-03-19T08:08:14Z',
  updatedAt: '2020-03-20T08:08:14Z',
  state: 'OPENED',
  userPermissions: mockUserPermissions,
  author: mockAuthor,
};

export const requirement3 = {
  iid: '3',
  title: 'Non modo carum sibi quemque, verum etiam vehementer carum esse',
  createdAt: '2020-03-19T08:08:25Z',
  updatedAt: '2020-03-20T08:08:25Z',
  state: 'OPENED',
  userPermissions: mockUserPermissions,
  author: mockAuthor,
};

export const mockRequirements = [requirement1, requirement2, requirement3];
