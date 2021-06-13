import axios from '~/lib/utils/axios_utils';

const extractAttachmentLinkUrls = (html) => {
  const parser = new DOMParser();
  const { body } = parser.parseFromString(html, 'text/html');
  const link = body.querySelector('a');
  const src = link.getAttribute('href');
  const { canonicalSrc } = link.dataset;

  return { src, canonicalSrc };
};

export const uploadFile = async ({ uploadsPath, renderMarkdown, file }) => {
  const formData = new FormData();
  formData.append('file', file, file.name);

  const { data } = await axios.post(uploadsPath || window.uploads_path, formData);
  const { markdown } = data.link;
  const rendered = await renderMarkdown(markdown);

  return extractAttachmentLinkUrls(rendered);
};
