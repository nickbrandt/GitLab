export const createTimestamper = () => {
  let timestamp = 0;

  const val = () => {
    return timestamp;
  };

  const next = () => {
    timestamp += 1;
    return timestamp;
  };

  const reset = () => {
    timestamp = 0;
  };

  return {
    val,
    next,
    reset,
  };
};

export default createTimestamper();
