export const firstDayOfWeekChoicesWithDefault = [['Monday', 1], ['Sunday', 7]];

export const languageChoices = [['English', 'en'], ['Danish', 'da'], ['Swedish', 'swe']];

export const integrationViews = [
  {
    name: 'sourcegraph',
    help_link: 'http://foo.com/help',
    message: 'Click %{linkStart}Foo%{linkEnd}!',
    message_url: 'http://foo.com',
  },
  {
    name: 'gitpod',
    help_link: 'http://bar.com/help',
    message: 'Click %{linkStart}Bar%{linkEnd}!',
    message_url: 'http://bar.com',
  },
];

export const userFields = {
  foo_enabled: true,
};

export const featureFlags = {
  userTimeSettings: true,
};
