<script>
import escape from 'lodash/escape';
import Tribute from 'tributejs';
import axios from '~/lib/utils/axios_utils';
import { spriteIcon } from '~/lib/utils/common_utils';

/**
 * Creates the HTML template for each row of the mentions dropdown.
 *
 * @param original An object from the array returned from the `autocomplete_sources/members` API
 * @returns {string} An HTML template
 */
function createMenuItemTemplate({ original }) {
  const rectAvatarClass = original.type === 'Group' ? 'rect-avatar' : '';

  const avatarTag = original.avatar_url
    ? `<img
        src="${original.avatar_url}"
        alt="${original.username} avatar"
        class="avatar ${rectAvatarClass} avatar-inline center s26"/>`
    : `<div class="avatar ${rectAvatarClass} avatar-inline center s26">
        ${original.username.charAt(0).toUpperCase()}</div>`;

  const name = escape(this.sanitize(original.name));

  const count = original.count && !original.mentionsDisabled ? ` (${original.count})` : '';

  const icon = original.mentionsDisabled
    ? spriteIcon('notifications-off', 's16 vertical-align-middle prepend-left-5')
    : '';

  return `${avatarTag}
    ${original.username}
    <small class="small font-weight-normal gl-color-inherit">${name}${count}</small>
    ${icon}`;
}

/**
 * Creates the list of users to show in the mentions dropdown.
 *
 * @param inputText The text entered by the user in the mentions input field
 * @param processValues Callback function to set the list of users to show in the mentions dropdown
 */
function getMembers(inputText, processValues) {
  if (this.members) {
    processValues(this.members);
  } else if (this.dataSources.members) {
    axios
      .get(this.dataSources.members)
      .then(response => {
        this.members = response.data;
        processValues(response.data);
      })
      .catch(() => {});
  } else {
    processValues([]);
  }
}

export default {
  name: 'GlMentions',
  props: {
    dataSources: {
      type: Object,
      required: false,
      default: () => gl.GfmAutoComplete?.dataSources || {},
    },
  },
  data() {
    return {
      members: undefined,
      options: {
        trigger: '@',
        fillAttr: 'username',
        lookup(value) {
          return value.name + value.username;
        },
        menuItemTemplate: createMenuItemTemplate.bind(this),
        values: getMembers.bind(this),
      },
    };
  },
  mounted() {
    const input = this.$slots.default[0].elm;
    this.tribute = new Tribute(this.options);
    this.tribute.attach(input);
  },
  beforeDestroy() {
    const input = this.$slots.default[0].elm;
    if (this.tribute) {
      this.tribute.detach(input);
    }
  },
  methods: {
    sanitize(str) {
      return str.replace(/<(?:.|\n)*?>/gm, '');
    },
  },
  render(h) {
    return h('div', this.$slots.default);
  },
};
</script>
