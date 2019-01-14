import { sprintf, s__ } from '~/locale';

export const toSeriesText = items => {
  if (items.length === 0) {
    return '';
  } else if (items.length === 1) {
    return items[0];
  } else if (items.length === 2) {
    return sprintf(s__('series|%{itemFirst} and %{itemLast}'), {
      itemFirst: items[0],
      itemLast: items[1],
    });
  }

  return items
    .slice(1)
    .reduce(
      (item, nextItem, idx) =>
        idx === items.length - 1
          ? sprintf(s__('series|%{item}, and %{nextItem}'), { item, nextItem })
          : sprintf(s__('series|%{item}, %{nextItem}'), { item, nextItem }),
      items[0],
    );
};

export default {
  toSeriesText,
};
