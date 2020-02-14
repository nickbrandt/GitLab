<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';

export default {
  name: 'LabelsSelector',
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    labels: {
      type: Array,
      required: true,
    },
    selectedLabelId: {
      type: Number,
      required: false,
      default: null,
    },
  },
  computed: {
    selectedLabel() {
      const { selectedLabelId, labels } = this;
      if (!selectedLabelId || !labels.length) return null;
      return labels.find(({ id }) => id === selectedLabelId);
    },
  },
  methods: {
    isSelectedLabel(id) {
      return this.selectedLabelId && id === this.selectedLabelId;
    },
  },
};
</script>
<template>
  <gl-dropdown class="w-100" toggle-class="overflow-hidden">
    <template slot="button-content">
      <span v-if="selectedLabel">
        <span
          :style="{ backgroundColor: selectedLabel.color }"
          class="d-inline-block dropdown-label-box"
        >
        </span>
        {{ selectedLabel.title }}
      </span>
      <span v-else>{{ __('Select a label') }}</span>
    </template>
    <gl-dropdown-item :active="!selectedLabelId" @click.prevent="$emit('clearLabel')"
      >{{ __('Select a label') }}
    </gl-dropdown-item>
    <gl-dropdown-item
      v-for="label in labels"
      :key="label.id"
      :active="isSelectedLabel(label.id)"
      @click.prevent="$emit('selectLabel', label.id)"
    >
      <span :style="{ backgroundColor: label.color }" class="d-inline-block dropdown-label-box">
      </span>
      {{ label.title }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
