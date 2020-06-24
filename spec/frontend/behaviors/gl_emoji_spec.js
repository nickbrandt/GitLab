import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { initEmojiMap, glEmojiTag, EMOJI_VERSION } from '~/emoji';
import installGlEmojiElement from '~/behaviors/gl_emoji';

describe('gl_emoji', () => {
  let mock;
  const emojiData = getJSONFixture('emojis/emojis.json');

  const emojiFixtureBomb = {
    name: 'bomb',
    moji: '💣',
    unicodeVersion: '6.0',
  };

  const emojiFixtureGreyQuestion = {
    name: 'grey_question',
    moji: '❔',
    unicodeVersion: '6.0',
  };

  beforeAll(() => {
    installGlEmojiElement();
  });

  async function markupToDomElement(markup) {
    const div = document.createElement('div');
    div.innerHTML = markup;
    document.body.appendChild(div);

    return div.firstElementChild;
  }

  function testGlEmojiImageFallback(element, name) {
    expect(element.tagName.toLowerCase()).toBe('img');
    expect(element.getAttribute('src')).toBe(`/-/emojis/${EMOJI_VERSION}/${name}.png`);
    expect(element.getAttribute('title')).toBe(`:${name}:`);
    expect(element.getAttribute('alt')).toBe(`:${name}:`);
  }

  const defaults = {
    sprite: false,
  };

  function testGlEmojiElement(element, name, unicodeVersion, unicodeMoji, options = {}) {
    const opts = { ...defaults, ...options };
    expect(element.tagName.toLowerCase()).toBe('gl-emoji');
    expect(element.dataset.name).toBe(name);
    expect(element.dataset.uni).toBe(unicodeVersion);

    const fallbackSpriteClass = `emoji-${name}`;
    if (opts.sprite) {
      expect(element.dataset.fallbackSpriteClass).toBe(fallbackSpriteClass);
    }

    expect(element.textContent.trim()).toBe(unicodeMoji);
  }

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(`/-/emojis/${EMOJI_VERSION}/emojis.json`).reply(200, emojiData);

    return initEmojiMap().catch(() => {});
  });

  afterEach(() => {
    mock.restore();

    document.body.innerHTML = '';
  });

  it('bomb emoji', async () => {
    const markup = glEmojiTag(emojiFixtureBomb.name);

    const glEmojiElement = await markupToDomElement(markup);
    testGlEmojiElement(
      glEmojiElement,
      emojiFixtureBomb.name,
      emojiFixtureBomb.unicodeVersion,
      emojiFixtureBomb.moji,
    );
  });

  it('bomb emoji with sprite fallback readiness', async () => {
    const markup = glEmojiTag(emojiFixtureBomb.name, {
      sprite: true,
    });

    const glEmojiElement = await markupToDomElement(markup);
    testGlEmojiElement(
      glEmojiElement,
      emojiFixtureBomb.name,
      emojiFixtureBomb.unicodeVersion,
      emojiFixtureBomb.moji,
      {
        sprite: true,
      },
    );
  });

  it('question mark when invalid emoji name given', async () => {
    const name = 'invalid_emoji';
    const markup = glEmojiTag(name);

    const glEmojiElement = await markupToDomElement(markup, true);
    testGlEmojiElement(
      glEmojiElement,
      emojiFixtureGreyQuestion.name,
      emojiFixtureGreyQuestion.unicodeVersion,
      emojiFixtureGreyQuestion.moji,
    );
  });
});
