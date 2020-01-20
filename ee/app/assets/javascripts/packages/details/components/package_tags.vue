<script>
import { GlBadge, GlIcon, GlSprintf, GlTooltipDirective } from '@gitlab/ui';

export default {
  name: 'PackageTags',
  components: {
    GlBadge,
    GlIcon,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    tagDisplayLimit: {
      type: Number,
      required: false,
      default: 2,
    },
    tags: {
      type: Array,
      required: true,
      default: () => [],
    },
  },
  computed: {
    tagCount() {
      return this.tags.length;
    },
    tagsToRender() {
      return this.tags.slice(0, this.tagDisplayLimit);
    },
    moreTagsDisplay() {
      return Math.max(0, this.tags.length - this.tagDisplayLimit);
    },
    moreTagsTooltip() {
      if (this.moreTagsDisplay) {
        return this.tags
          .slice(this.tagDisplayLimit)
          .map(x => x.name)
          .join(', ');
      }

      return '';
    },
  },
};
</script>

<template>
  <div class="d-flex align-items-center">
    <gl-icon name="labels" class="append-right-8" />
    <strong class="append-right-8 js-tags-count">{{ n__('%d tag', '%d tags', tagCount) }}</strong>
    <gl-badge
      v-for="(tag, index) in tagsToRender"
      :key="index"
      ref="tagBadge"
      class="append-right-4"
      variant="info"
      >{{ tag.name }}</gl-badge
    >

    <gl-badge
      v-if="moreTagsDisplay"
      ref="moreBadge"
      v-gl-tooltip
      variant="light"
      :title="moreTagsTooltip"
      ><gl-sprintf message="+%{tags} more">
        <template #tags>
          {{ moreTagsDisplay }}
        </template>
      </gl-sprintf></gl-badge
    >
  </div>
</template>
