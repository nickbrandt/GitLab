<script>
import { VALID_DESIGN_FILE_MIMETYPE } from '../../constants';

export default {
  VALID_DESIGN_FILE_MIMETYPE,
};
</script>

<template>
  <input
    type="file"
    name="design_file"
    :accept="$options.VALID_DESIGN_FILE_MIMETYPE.mimetype"
    class="hide"
    multiple
    @change="$emit('change', $event)"
  />
</template>
