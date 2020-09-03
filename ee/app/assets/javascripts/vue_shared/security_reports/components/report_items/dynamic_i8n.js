import Jed from 'jed';
import { languageCode } from "~/locale";

/**
 * Create a new Jed instance from an object of the form:
 *
 *   {
 *     'key1': [
 *       { 'lang': 'en', 'value': 'Hello World' },
 *       { 'lang': 'de', 'value': 'Hallo Welt' },
 *     ],
 *     'key2': [
 *       { 'lang': 'en', 'value': 'Hello World' },
 *       { 'lang': 'de', 'value': 'Hallo Welt' },
 *     ],
 *   }
 *
 * The returned Jed instance can be used like so:
 *
 *   locale = createLocale({..});
 *   var text = locale.translate('key2').fetch();
 */
function createLocale(messages) {
  const localeData = {
    en: {
      '': { domain: 'en', lang: 'en' },
    },
  };
  localeData[languageCode()] = {
    '': { domain: languageCode(), lang: languageCode() },
  };

  Object.entries(messages).forEach(([key, items]) => {
    items.forEach(item => {
      let langItem = localeData[item.lang];
      if (langItem === undefined) {
        langItem = {
          '': { domain: item.lang, lang: item.lang },
        };
        localeData[item.lang] = langItem;
      }
      langItem[key] = [ item.value ];
    });
  });

  const result = new Jed({
    domain: languageCode(),
    locale_data: localeData,
  });
  return result;
}

export function dynI8n(messages) {
  if (messages.length === '') {
    return '';
  }
  const defaultValue = messages[0].value;
  const tmpData = {};
  tmpData[defaultValue] = messages;
  const locale = createLocale(tmpData);
  try {
    return locale.translate(defaultValue).fetch();
  } catch(e) {
    return defaultValue;
  }
}
