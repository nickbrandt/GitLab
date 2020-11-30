export function parseDataset(data) {
  const shouldParse = [
    'themes',
    'languageChoices',
    'firstDayOfWeekChoicesWithDefault',
    'integrationViews',
    'userFields',
  ];

  return Object.keys(data).reduce((memo, key) => {
    let value = data[key];
    if (shouldParse.includes(key)) {
      try {
        value = JSON.parse(data[key]);
      } catch (error) {
        throw new Error(`Unable to parse "${key}". The original value was: ${value}. ${error}`);
      }
    }

    return { ...memo, [key]: value };
  }, {});
}
