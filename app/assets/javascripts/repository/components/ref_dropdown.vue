<script>
import { GlDropdown, GlDropdownItem, GlDropdownSectionHeader } from '@gitlab/ui';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { s__ } from '~/locale';

const EMPTY_DROPDOWN_TEXT = s__('Repository|Select branch/tag');

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlDropdownSectionHeader,
  },
  props: {
    refsProjectPath: {
      type: String,
      required: true,
    },
    currentRef: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      branches: [],
      tags: [],
      loading: true,
      selectedRef: this.getDefaultRef(),
    };
  },
  computed: {
    hasBranches() {
      return Boolean(this.branches?.length);
    },
    hasTags() {
      return Boolean(this.tags?.length);
    },
  },
  mounted() {
    this.fetchBranchesAndTags();
  },
  methods: {
    fetchBranchesAndTags() {
      this.loading = true;

      return axios
        .get(this.refsProjectPath)
        .then(({ data }) => {
          this.branches = data.Branches || [];
          this.tags = data.Tags || [];
        })
        .catch(() => {
          createFlash({
            message: s__(
              'There was an error while searching the branch/tag list. Please try again.',
            ),
          });
        })
        .finally(() => {
          this.loading = false;
        });
    },
    getDefaultRef() {
      return this.currentRef || EMPTY_DROPDOWN_TEXT;
    },
    onClick(ref) {
      this.setSelectedRef(ref);
    },
    setSelectedRef(ref) {
      this.selectedRef = ref || EMPTY_DROPDOWN_TEXT;
    },
  },
};
</script>

<template>
  <div class="gl-mr-4 gl-w-20">
    <gl-dropdown
      class="gl-w-full gl-font-monospace"
      toggle-class="gl-min-w-0"
      :text="selectedRef"
      :header-text="s__('Repository|Switch branch/tag')"
      :loading="loading"
    >
      <gl-dropdown-section-header v-if="hasBranches">
        {{ s__('Repository|Branches') }}
      </gl-dropdown-section-header>
      <gl-dropdown-item
        v-for="branch in branches"
        :key="branch"
        is-check-item
        :is-checked="selectedRef === branch"
        @click="onClick(branch)"
      >
        {{ branch }}
      </gl-dropdown-item>
      <gl-dropdown-section-header v-if="hasTags">
        {{ s__('Repository|Tags') }}
      </gl-dropdown-section-header>
      <gl-dropdown-item
        v-for="tag in tags"
        :key="tag"
        is-check-item
        :is-checked="selectedRef === tag"
        @click="onClick(tag)"
      >
        {{ tag }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
