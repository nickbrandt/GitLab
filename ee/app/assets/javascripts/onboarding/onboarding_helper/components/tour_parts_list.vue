<script>
import { s__, sprintf } from '~/locale';

export default {
  name: 'TourPartsList',
  props: {
    tourTitles: {
      type: Array,
      required: true,
    },
    activeTour: {
      type: Number,
      required: false,
      default: null,
    },
    totalStepsForTour: {
      type: Number,
      required: false,
      default: 0,
    },
    completedSteps: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  computed: {
    stepsCompletedInfo() {
      return sprintf(s__('UserOnboardingTour|%{completed}/%{total} steps completed'), {
        completed: this.completedSteps,
        total: this.totalStepsForTour,
      });
    },
  },
  methods: {
    isActiveTour(tourNo) {
      return tourNo === this.activeTour;
    },
  },
};
</script>

<template>
  <ul class="list-unstyled">
    <li
      v-for="tour in tourTitles"
      :key="tour.id"
      class="tour-item my-2 px-2"
      :class="{ active: isActiveTour(tour.id), 'py-2': isActiveTour(tour.id) }"
    >
      <span class="tour-title" :class="{ 'text-info': isActiveTour(tour.id) }"
        ><strong>{{ tour.id }}</strong> {{ tour.title }}</span
      >
      <div v-if="isActiveTour(tour.id)" class="text-secondary">{{ stepsCompletedInfo }}</div>
    </li>
  </ul>
</template>

<style scoped>
.tour-item.active {
  background: #f6fafe;
}
.tour-item.active .tour-title {
  font-weight: bold;
}
</style>
