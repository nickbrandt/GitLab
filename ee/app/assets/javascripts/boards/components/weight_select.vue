<script>
import _ from 'underscore';
import WeightSelect from 'ee/weight_select';
import { GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';

const ANY_WEIGHT = {
  label: __('Any Weight'),
  selectValue: 'Any',
  value: null,
  valueClass: 'text-secondary',
};

const NO_WEIGHT = {
  label: __('No Weight'),
  selectValue: 'None',
  value: -1,
};

function unstringifyValue(value) {
  if (!_.isString(value)) {
    return value;
  }
  const numValue = Number(value);
  return Number.isNaN(numValue) ? null : numValue;
}

function getWeightValueFromSelect(selectValue) {
  switch (selectValue) {
    case ANY_WEIGHT.selectValue:
      return ANY_WEIGHT.value;
    case NO_WEIGHT.selectValue:
      return NO_WEIGHT.value;
    case null:
    case undefined:
      return ANY_WEIGHT.value;
    default:
      return Number(selectValue);
  }
}

function getWeightFromValue(strValue) {
  const value = unstringifyValue(strValue);
  switch (value) {
    case ANY_WEIGHT.value:
      return ANY_WEIGHT;
    case NO_WEIGHT.value:
      return NO_WEIGHT;
    default:
      return {
        label: String(value),
        selectValue: value,
        value,
      };
  }
}

export default {
  components: {
    GlLoadingIcon,
  },
  props: {
    board: {
      type: Object,
      required: true,
    },
    value: {
      type: [Number, String],
      required: false,
      default: ANY_WEIGHT.value,
    },
    canEdit: {
      type: Boolean,
      required: false,
      default: false,
    },
    weights: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      fieldName: 'weight',
    };
  },
  computed: {
    selectedWeight() {
      return getWeightFromValue(this.value);
    },

    valueClass() {
      return this.selectedWeight.valueClass || 'bold';
    },
    valueText() {
      return this.selectedWeight.label;
    },
  },
  mounted() {
    this.weightDropdown = new WeightSelect(this.$refs.dropdownButton, {
      handleClick: this.selectWeight,
      selected: this.value,
      fieldName: this.fieldName,
    });
  },
  methods: {
    isSelected(weight) {
      return this.selectedWeight.selectValue === weight;
    },
    selectWeight(weight) {
      this.board.weight = getWeightValueFromSelect(weight);
    },
  },
};
</script>

<template>
  <div class="block weight">
    <div class="title append-bottom-10">
      Weight
      <button v-if="canEdit" type="button" class="edit-link btn btn-blank float-right">
        {{ __('Edit') }}
      </button>
    </div>
    <div :class="valueClass" class="value">{{ valueText }}</div>
    <div class="selectbox" style="display: none;">
      <input :name="fieldName" type="hidden" />
      <div class="dropdown">
        <button
          ref="dropdownButton"
          class="dropdown-menu-toggle js-weight-select wide"
          type="button"
          data-default-label="Weight"
          data-toggle="dropdown"
        >
          <span class="dropdown-toggle-text is-default">{{ __('Weight') }}</span>
          <i aria-hidden="true" data-hidden="true" class="fa fa-chevron-down"> </i>
        </button>
        <div class="dropdown-menu dropdown-select dropdown-menu-selectable dropdown-menu-weight">
          <div class="dropdown-content ">
            <ul>
              <li v-for="weight in weights" :key="weight">
                <a :class="{ 'is-active': isSelected(weight) }" :data-id="weight" href="#">
                  {{ weight }}
                </a>
              </li>
            </ul>
          </div>
          <div class="dropdown-loading"><gl-loading-icon /></div>
        </div>
      </div>
    </div>
  </div>
</template>
