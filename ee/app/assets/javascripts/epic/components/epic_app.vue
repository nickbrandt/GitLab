<script>
import EpicHeader from './epic_header.vue';
import EpicBody from './epic_body.vue';

export default {
  components: {
    EpicHeader,
    EpicBody,
  },
};
</script>

<template>
  <div class="epic-page-container">
    <epic-header/>
    <epic-body/>
  </div>
</template>
