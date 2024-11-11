import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import ModelVersionCreate from '~/ml/model_registry/components/model_version_create.vue';
import ImportArtifactZone from '~/ml/model_registry/components/import_artifact_zone.vue';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import { uploadModel } from '~/ml/model_registry/services/upload_model';
import createModelVersionMutation from '~/ml/model_registry/graphql/mutations/create_model_version.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { MODEL_VERSION_CREATION_MODAL_ID } from '~/ml/model_registry/constants';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { createModelVersionResponses } from '../graphql_mock_data';

Vue.use(VueApollo);

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrlWithAlerts: jest.fn(),
}));

jest.mock('~/ml/model_registry/services/upload_model', () => ({
  uploadModel: jest.fn(() => Promise.resolve()),
}));

describe('ModelVersionCreate', () => {
  let wrapper;
  let apolloProvider;

  const file = { name: 'file.txt', size: 1024 };
  const anotherFile = { name: 'another file.txt', size: 10 };
  const files = [file, anotherFile];

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();
  });

  afterEach(() => {
    apolloProvider = null;
  });

  const createWrapper = (
    createResolver = jest.fn().mockResolvedValue(createModelVersionResponses.success),
    provide = {},
  ) => {
    const requestHandlers = [[createModelVersionMutation, createResolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(ModelVersionCreate, {
      provide: {
        projectPath: 'some/project',
        maxAllowedFileSize: 99999,
        latestVersion: null,
        markdownPreviewPath: '/markdown-preview',
        ...provide,
      },
      directives: {
        GlModal: createMockDirective('gl-modal'),
      },
      propsData: {
        modelGid: 'gid://gitlab/Ml::Model/1',
      },
      apolloProvider,
      stubs: {
        UploadDropzone,
      },
    });
  };

  const findModalButton = () => wrapper.findByText('Create model version');
  const findVersionInput = () => wrapper.findByTestId('versionId');
  const findDescriptionInput = () => wrapper.findByTestId('descriptionId');
  const findImportArtifactZone = () => wrapper.findComponent(ImportArtifactZone);
  const zone = () => wrapper.findComponent(UploadDropzone);
  const findGlModal = () => wrapper.findComponent(GlModal);
  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const submitForm = async () => {
    findGlModal().vm.$emit('primary', new Event('primary'));
    await waitForPromises();
  };
  const artifactZoneLabel = () => wrapper.findByTestId('uploadArtifactsHeader');
  const findMarkdownEditor = () => wrapper.findComponent(MarkdownEditor);

  describe('Initial state', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the modal button', () => {
      expect(findModalButton().text()).toBe('Create model version');
      expect(findModalButton().attributes('variant')).toBe('confirm');
      expect(findModalButton().attributes('category')).toBe('primary');
      expect(getBinding(findModalButton().element, 'gl-modal').value).toBe(
        MODEL_VERSION_CREATION_MODAL_ID,
      );
      expect(findModalButton().attributes('disabled')).toBeUndefined();
      expect(findModalButton().attributes('category')).toBe('primary');
      expect(findModalButton().attributes('variant')).toBe('confirm');
    });

    describe('Modal open', () => {
      it('renders the version input', () => {
        expect(findVersionInput().exists()).toBe(true);
      });

      it('renders the version input label for initial state', () => {
        expect(wrapper.findByTestId('versionDescriptionId').attributes().description).toBe(
          'Enter a semantic version.',
        );
        expect(wrapper.findByTestId('versionDescriptionId').attributes('invalid-feedback')).toBe(
          '',
        );
        expect(wrapper.findByTestId('versionDescriptionId').attributes('valid-feedback')).toBe('');
      });

      it('renders the description input', () => {
        expect(findDescriptionInput().exists()).toBe(true);
      });

      it('renders the import artifact zone input', () => {
        expect(findImportArtifactZone().props()).toEqual({
          path: null,
          submitOnSelect: false,
        });
      });

      it('renders the import modal', () => {
        expect(findGlModal().props()).toMatchObject({
          modalId: 'create-model-version-modal',
          title: 'Create model version & import artifacts',
          size: 'lg',
        });
      });

      it('disables the create button in the modal when semver is incorrect', () => {
        expect(findGlModal().props('actionPrimary')).toEqual({
          attributes: { variant: 'confirm', disabled: true },
          text: 'Create & import',
        });
      });

      it('renders the cancel button in the modal', () => {
        expect(findGlModal().props('actionSecondary')).toEqual({
          text: 'Cancel',
          attributes: { variant: 'default' },
        });
      });

      it('does not render the alert by default', () => {
        expect(findGlAlert().exists()).toBe(false);
      });

      it('displays the title of the artifacts uploader', () => {
        expect(artifactZoneLabel().attributes('label')).toBe('Upload artifacts');
      });
    });
  });

  describe('Markdown editor', () => {
    it('should show markdown editor', () => {
      createWrapper();

      expect(findMarkdownEditor().exists()).toBe(true);

      expect(findMarkdownEditor().props()).toMatchObject({
        enableContentEditor: true,
        formFieldProps: {
          id: 'model-version-description',
          name: 'model-version-description',
          placeholder: 'Enter a model version description',
        },
        markdownDocsPath: '/help/user/markdown',
        renderMarkdownPath: '/markdown-preview',
        uploadsPath: '',
      });
    });
  });

  describe('It reacts to semantic version input', () => {
    beforeEach(() => {
      createWrapper();
    });
    it('renders the version input label for initial state', () => {
      expect(wrapper.findByTestId('versionDescriptionId').attributes('invalid-feedback')).toBe('');
      expect(findGlModal().props('actionPrimary')).toEqual({
        attributes: { variant: 'confirm', disabled: true },
        text: 'Create & import',
      });
    });
    it.each(['1.0', '1', 'abc', '1.abc', '1.0.0.0'])(
      'renders the version input label for invalid state',
      async (version) => {
        findVersionInput().vm.$emit('input', version);
        await nextTick();
        expect(wrapper.findByTestId('versionDescriptionId').attributes('invalid-feedback')).toBe(
          'Version is not a valid semantic version.',
        );
        expect(findGlModal().props('actionPrimary')).toEqual({
          attributes: { variant: 'confirm', disabled: true },
          text: 'Create & import',
        });
      },
    );
    it.each(['1.0.0', '0.0.0-b', '24.99.99-b99'])(
      'renders the version input label for valid state',
      async (version) => {
        findVersionInput().vm.$emit('input', version);
        await nextTick();
        expect(wrapper.findByTestId('versionDescriptionId').attributes('valid-feedback')).toBe(
          'Version is valid semantic version.',
        );
        expect(findGlModal().props('actionPrimary')).toEqual({
          attributes: { variant: 'confirm', disabled: false },
          text: 'Create & import',
        });
      },
    );
  });

  describe('Latest version available', () => {
    beforeEach(() => {
      createWrapper(undefined, { latestVersion: '1.2.3' });
    });

    it('renders the version input label', () => {
      expect(wrapper.findByTestId('versionDescriptionId').attributes().description).toBe(
        'Enter a semantic version. Latest version is 1.2.3',
      );
    });
  });

  describe('Successful flow', () => {
    beforeEach(async () => {
      createWrapper();
      findVersionInput().vm.$emit('input', '1.0.0');
      findDescriptionInput().vm.$emit('input', 'My model version description');
      zone().vm.$emit('change', files);
      jest.spyOn(apolloProvider.defaultClient, 'mutate');

      await submitForm();
    });

    it('Makes a create mutation upon confirm', () => {
      expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith(
        expect.objectContaining({
          mutation: createModelVersionMutation,
          variables: {
            modelId: 'gid://gitlab/Ml::Model/1',
            projectPath: 'some/project',
            version: '1.0.0',
            description: 'My model version description',
          },
        }),
      );
    });

    it('Uploads a file mutation upon confirm', () => {
      expect(uploadModel).toHaveBeenCalledWith({
        file,
        importPath: '/api/v4/projects/1/packages/ml_models/1/files/',
        subfolder: '',
        maxAllowedFileSize: 99999,
        onUploadProgress: expect.any(Function),
        cancelToken: expect.any(Object),
      });
    });

    it('Visits the model versions page upon successful create mutation', async () => {
      createWrapper();

      await submitForm();

      expect(visitUrlWithAlerts).toHaveBeenCalledWith('/some/project/-/ml/models/1/versions/1', [
        {
          id: 'import-artifact-alert',
          message: 'Artifacts uploaded successfully.',
          variant: 'info',
        },
      ]);
    });

    it('clicking on secondary button clears the form', async () => {
      createWrapper();

      await findVersionInput().vm.$emit('input', '1.0.0');

      await findGlModal().vm.$emit('secondary');

      expect(findVersionInput().attributes('value')).toBe(undefined);
    });
  });

  describe('Failed flow', () => {
    it('Displays an alert upon failed create mutation', async () => {
      const failedCreateResolver = jest.fn().mockResolvedValue(createModelVersionResponses.failure);
      createWrapper(failedCreateResolver);

      await submitForm();

      expect(findGlAlert().text()).toBe('Version is invalid');
    });

    describe('Failed flow with file upload retried', () => {
      beforeEach(async () => {
        createWrapper();
        findVersionInput().vm.$emit('input', '1.0.0');
        zone().vm.$emit('change', files);
        await nextTick();
        uploadModel.mockRejectedValueOnce('Artifact import error.');

        await submitForm();
      });

      it('Visits the model versions page upon successful create mutation', async () => {
        await submitForm();

        expect(visitUrlWithAlerts).toHaveBeenCalledWith('/some/project/-/ml/models/1/versions/1', [
          {
            id: 'import-artifact-alert',
            message: 'Artifact uploads completed with errors. file.txt: Artifact import error.',
            variant: 'danger',
          },
        ]);
      });

      it('Uploads the model upon retry', async () => {
        await submitForm();

        expect(uploadModel).toHaveBeenCalledWith({
          file,
          importPath: '/api/v4/projects/1/packages/ml_models/1/files/',
          subfolder: '',
          maxAllowedFileSize: 99999,
          onUploadProgress: expect.any(Function),
          cancelToken: expect.any(Object),
        });
      });
    });
  });
});
