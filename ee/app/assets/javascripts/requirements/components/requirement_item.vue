<script>
import { escape as esc } from 'lodash';
import {
  GlPopover,
  GlLink,
  GlAvatar,
  GlDeprecatedButton,
  GlIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { getTimeago } from '~/lib/utils/datetime_utility';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  components: {
    GlPopover,
    GlLink,
    GlAvatar,
    GlDeprecatedButton,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeagoMixin],
  props: {
    requirement: {
      type: Object,
      required: true,
      validator: value =>
        ['iid', 'state', 'userPermissions', 'title', 'createdAt', 'updatedAt', 'author'].every(
          prop => value[prop],
        ),
    },
  },
  computed: {
    reference() {
      return `REQ-${this.requirement.iid}`;
    },
    canUpdate() {
      return this.requirement.userPermissions.updateRequirement;
    },
    canArchive() {
      return this.requirement.userPermissions.adminRequirement;
    },
    createdAt() {
      return sprintf(__('created %{timeAgo}'), {
        timeAgo: esc(getTimeago().format(this.requirement.createdAt)),
      });
    },
    updatedAt() {
      return sprintf(__('updated %{timeAgo}'), {
        timeAgo: esc(getTimeago().format(this.requirement.updatedAt)),
      });
    },
    author() {
      return this.requirement.author;
    },
  },
  methods: {
    /**
     * This is needed as an independent method since
     * when user changes current page, `$refs.authorLink`
     * will be null until next page results are loaded & rendered.
     */
    getAuthorPopoverTarget() {
      if (this.$refs.authorLink) {
        return this.$refs.authorLink.$el;
      }
      return '';
    },
  },
};
</script>

<template>
  <li class="issue requirement">
    <div class="issue-box">
      <div class="issuable-info-container">
        <span class="issuable-reference text-muted d-none d-sm-block mr-2">{{ reference }}</span>
        <div class="issuable-main-info">
          <span class="issuable-reference text-muted d-block d-sm-none">{{ reference }}</span>
          <div class="issue-title title">
            <span class="issue-title-text">{{ requirement.title }}</span>
          </div>
          <div class="issuable-info">
            <span class="issuable-authored d-none d-sm-inline-block">
              <span
                v-gl-tooltip:tooltipcontainer.bottom
                :title="tooltipTitle(requirement.createdAt)"
                >{{ createdAt }}</span
              >
              {{ __('by') }}
              <gl-link ref="authorLink" class="author-link js-user-link" :href="author.webUrl">
                <span class="author">{{ author.name }}</span>
              </gl-link>
            </span>
          </div>
        </div>
        <div class="issuable-meta">
          <ul v-if="canUpdate || canArchive" class="controls flex-column flex-sm-row">
            <li v-if="canUpdate" class="requirement-edit d-sm-block">
              <gl-deprecated-button v-gl-tooltip size="sm" class="border-0" :title="__('Edit')">
                <gl-icon name="pencil" />
              </gl-deprecated-button>
            </li>
            <li v-if="canArchive" class="requirement-archive d-sm-block">
              <gl-deprecated-button v-gl-tooltip size="sm" class="border-0" :title="__('Archive')">
                <gl-icon name="archive" />
              </gl-deprecated-button>
            </li>
          </ul>
          <div class="float-right issuable-updated-at d-none d-sm-inline-block">
            <span
              v-gl-tooltip:tooltipcontainer.bottom
              :title="tooltipTitle(requirement.updatedAt)"
              >{{ updatedAt }}</span
            >
          </div>
        </div>
      </div>
    </div>
    <gl-popover :target="getAuthorPopoverTarget()" triggers="hover focus" placement="top">
      <div class="user-popover p-0 d-flex">
        <div class="p-1 flex-shrink-1">
          <gl-avatar :entity-name="author.name" :alt="author.name" :src="author.avatarUrl" />
        </div>
        <div class="p-1 w-100">
          <h5 class="m-0">{{ author.name }}</h5>
          <div class="text-secondary mb-2">@{{ author.username }}</div>
        </div>
      </div>
    </gl-popover>
  </li>
</template>
