<script>
export default {
  name: 'SummaryTable',
  props: {
    items: {
      type: Array,
      required: true,
    },
  },
};
</script>
<template>
  <div class="wrapper mt-3">
    <div class="card">
      <div class="card-header font-weight-bold">{{ __('Recent Activity') }}</div>
      <div class="content-block">
        <div class="container-fluid">
          <div class="row">
            <div class="col-sm-3"></div>
            <div
              v-for="{ title, value } in items"
              :key="title"
              class="col-sm-3 col-12 column text-center"
            >
              <h3 class="header">{{ value }}</h3>
              <p class="text">{{ title }}</p>
            </div>
            <div class="col-sm-3"></div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
