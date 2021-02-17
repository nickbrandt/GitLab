<script>
export default {
  name: 'ReplyPlaceholder',
  props: {
    placeholderText: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <textarea
    ref="textarea"
    rows="1"
    class="reply-placeholder-text-field js-vue-discussion-reply"
    :placeholder="placeholderText"
    :aria-label="__('Reply to comment')"
    @focus="$emit('focus')"
  ></textarea>
</template>
