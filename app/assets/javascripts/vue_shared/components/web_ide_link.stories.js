

import CEWebIdeLink from './web_ide_link.vue';


export default {
  component: CEWebIdeLink,
  title: 'vue_shared/components/web_ide_link',
  
};

const Template = (args, { argTypes }) => ({
  components: { CEWebIdeLink },
  
  props: Object.keys(argTypes),
  template: '<CEWebIdeLink v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  "isFork": false,
  "needsToFork": false,
  "needsToForkWithWebIde": false,
  "gitpodEnabled": false,
  "isBlob": false,
  "showEditButton": false,
  "showWebIdeButton": true,
  "showGitpodButton": false,
  "showPipelineEditorButton": false,
  "editUrl": "",
  "pipelineEditorUrl": "/qa-sandbox-dcba2195acdb/qa-test-2024-11-19-15-33-01-cc96c61102059524/duo-chat-explain-code-73fba4fd468fa779/-/ci/editor?branch_name=main",
  "webIdeUrl": "/-/ide/project/qa-sandbox-dcba2195acdb/qa-test-2024-11-19-15-33-01-cc96c61102059524/duo-chat-explain-code-73fba4fd468fa779/edit/main/-/",
  "webIdeText": "",
  "gitpodUrl": "",
  "gitpodText": "",
  "disableForkModal": false,
  "forkPath": "/qa-sandbox-dcba2195acdb/qa-test-2024-11-19-15-33-01-cc96c61102059524/duo-chat-explain-code-73fba4fd468fa779/-/forks/new",
  "forkModalId": "modal-confirm-fork-webide",
  "webIdePromoPopoverImg": "/assets/web-ide-promo-popover-9e59939b3b450a7ea385a520971151abb09ddad46141c333d6dcc783b9b91522.svg",
  "cssClasses": "gl-w-full sm:gl-w-auto"
};
