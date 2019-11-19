import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { convertToSnakeCase } from '~/lib/utils/text_utility';
import { isString } from 'underscore';

const EVENT_TYPE_LABEL = 'label';

export const isStartEvent = ev => Boolean(ev) && Boolean(ev.canBeStartEvent) && ev.canBeStartEvent;

export const eventToOption = (obj = null) => {
  if (!obj || (!obj.text && !obj.identifier)) return null;
  const { name: text = '', identifier: value = null } = obj;
  return { text, value };
};

export const getAllowedEndEvents = (events = [], targetIdentifier = null) => {
  if (!targetIdentifier || !events.length) return [];
  const st = events.find(({ identifier }) => identifier === targetIdentifier);
  return st && st.allowedEndEvents ? st.allowedEndEvents : [];
};

export const eventsByIdentifier = (events = [], targetIdentifier = []) => {
  if (!targetIdentifier || !targetIdentifier.length || !events.length) return [];
  return events.filter(({ identifier = '' }) => targetIdentifier.includes(identifier));
};

export const isLabelEvent = (labelEvents = [], ev = null) =>
  Boolean(ev) && labelEvents.length && labelEvents.includes(ev);

export const getLabelEventsIdentifiers = (events = []) =>
  events.filter(ev => ev.type && ev.type === EVENT_TYPE_LABEL).map(i => i.identifier);

export const transformRawStages = (stages = []) =>
  stages
    .map(({ title, ...rest }) => ({
      ...convertObjectPropsToCamelCase(rest, { deep: true }),
      slug: convertToSnakeCase(title),
      title,
    }))
    .sort((a, b) => a.id > b.id);

export const nestQueryStringKeys = (obj = null, targetKey = '') => {
  if (!obj || !isString(targetKey) || !targetKey.length) return {};
  return Object.entries(obj).reduce((prev, [key, value]) => {
    const customKey = `${targetKey}[${key}]`;
    return { ...prev, [customKey]: value };
  }, {});
};
