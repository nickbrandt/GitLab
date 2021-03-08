import { chunk, memoize } from 'lodash';
import { initEmojiMap, getEmojiCategoryMap } from '~/emoji';

export const generateCategoryHeight = (emojisLength) => emojisLength * 34 + 29;

export const getEmojiCategories = memoize(async () => {
  await initEmojiMap();

  const categories = await getEmojiCategoryMap();
  let top = 0;

  return Object.freeze(
    Object.keys(categories).reduce((acc, category) => {
      const emojis = chunk(categories[category], 9);
      const height = generateCategoryHeight(emojis.length);
      const newAcc = {
        ...acc,
        [category]: { emojis, height, top },
      };
      top += height;

      return newAcc;
    }, {}),
  );
});
