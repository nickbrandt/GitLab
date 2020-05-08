const downloadPatchHelper = (patch, opts = {}) => {
  const mergedOpts = {
    isEncoded: true,
    ...opts,
  };

  const url = `data:text/plain;base64,${mergedOpts.isEncoded ? patch : btoa(patch)}`;
  const link = document.createElement('a');
  link.href = url;
  link.setAttribute('download', 'remediation.patch');
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
};

export { downloadPatchHelper as default };
