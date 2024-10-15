# frozen_string_literal: true

module QA
  RSpec.describe 'Package', :orchestrated, :skip_live_env, product_group: :container_registry do
    describe 'Self-managed Container Registry' do
      include Support::Helpers::MaskToken

      let(:project) { create(:project, :private, name: 'project-with-registry', template_name: 'express') }
      let(:project_deploy_token) do
        create(:project_deploy_token,
          name: 'registry-deploy-token',
          project: project,
          scopes: %w[
            read_repository
            read_package_registry
            write_package_registry
            read_registry
            write_registry
          ])
      end

      let!(:runner) do
        Resource::ProjectRunner.fabricate! do |runner|
          runner.name = "qa-runner-#{Time.now.to_i}"
          runner.tags = ["runner-for-#{project.name}"]
          runner.executor = :docker
          runner.project = project
        end
      end

      let(:personal_access_token) { Runtime::Env.personal_access_token }

      before do
        Flow::Login.sign_in
        project.visit!
      end

      context "when tls is disabled" do
        where do
          {
            'using docker:20.10.23 and a personal access token' => {
              docker_client_version: 'docker:20.10.23',
              authentication_token_type: :personal_access_token,
              token_name: 'Personal Access Token',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/412807'
            },
            'using docker:20.10.23 and a project deploy token' => {
              docker_client_version: 'docker:20.10.23',
              authentication_token_type: :project_deploy_token,
              token_name: 'Deploy Token',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/412808'
            },
            'using docker:20.10.23 and a ci job token' => {
              docker_client_version: 'docker:20.10.23',
              authentication_token_type: :ci_job_token,
              token_name: 'Job Token',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/412809'
            },
            'using docker:23.0.6 and a personal access token' => {
              docker_client_version: 'docker:23.0.6',
              authentication_token_type: :personal_access_token,
              token_name: 'Personal Access Token',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/412810'
            },
            'using docker:23.0.6 and a project deploy token' => {
              docker_client_version: 'docker:23.0.6',
              authentication_token_type: :project_deploy_token,
              token_name: 'Deploy Token',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/412813'
            },
            'using docker:23.0.6 and a ci job token' => {
              docker_client_version: 'docker:23.0.6',
              authentication_token_type: :ci_job_token,
              token_name: 'Job Token',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/412814'
            },
            'using docker:24.0.1 and a personal access token' => {
              docker_client_version: 'docker:24.0.1',
              authentication_token_type: :personal_access_token,
              token_name: 'Personal Access Token',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/412817'
            },
            'using docker:24.0.1 and a project deploy token' => {
              docker_client_version: 'docker:24.0.1',
              authentication_token_type: :project_deploy_token,
              token_name: 'Deploy Token',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/412818'
            },
            'using docker:24.0.1 and a ci job token' => {
              docker_client_version: 'docker:24.0.1',
              authentication_token_type: :ci_job_token,
              token_name: 'Job Token',
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/412819'
            }
          }
        end

        with_them do
          let(:auth_token) do
            case authentication_token_type
            when :personal_access_token
              use_ci_variable(name: 'PERSONAL_ACCESS_TOKEN', value: personal_access_token, project: project)
            when :project_deploy_token
              use_ci_variable(name: 'PROJECT_DEPLOY_TOKEN', value: project_deploy_token.token, project: project)
            when :ci_job_token
              '$CI_JOB_TOKEN'
            end
          end

          let(:auth_user) do
            case authentication_token_type
            when :personal_access_token
              "$CI_REGISTRY_USER"
            when :project_deploy_token
              "\"#{project_deploy_token.username}\""
            when :ci_job_token
              'gitlab-ci-token'
            end
          end

          it "pushes image and deletes tag", :registry, testcase: params[:testcase] do
            Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
              create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
                {
                  action: 'create',
                  file_path: '.gitlab-ci.yml',
                  content: <<~YAML
                    build:
                      image: "#{docker_client_version}"
                      stage: build
                      services:
                      - name: "#{docker_client_version}-dind"
                        command: ["--insecure-registry=gitlab.test:5050"]
                      variables:
                        IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG
                      script:
                        - docker login -u #{auth_user} -p #{auth_token} gitlab.test:5050
                        - docker build -t $IMAGE_TAG .
                        - docker push $IMAGE_TAG
                      tags:
                        - "runner-for-#{project.name}"
                  YAML
                }
              ])
            end

            Flow::Pipeline.visit_latest_pipeline

            Page::Project::Pipeline::Show.perform do |pipeline|
              pipeline.click_job('build')
            end

            Page::Project::Job::Show.perform do |job|
              expect(job).to be_successful(timeout: 800)
            end

            Page::Project::Menu.perform(&:go_to_container_registry)

            Page::Project::Registry::Show.perform do |registry|
              expect(registry).to have_registry_repository(project.name)

              registry.click_on_image(project.name)
              expect(registry).to have_tag('master')
            end
          end
        end
      end

      context 'when tls is enabled' do
        it(
          'pushes image and deletes tag',
          :registry_tls,
          testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347591'
        ) do
          Support::Retrier.retry_on_exception(max_attempts: 3, sleep_interval: 2) do
            create(:commit, project: project, commit_message: 'Add .gitlab-ci.yml', actions: [
              {
                action: 'create',
                file_path: '.gitlab-ci.yml',
                content: <<~YAML
                  build:
                    image: docker:23.0.6
                    stage: build
                    services:
                      - name: docker:23.0.6-dind
                        command:
                          - /bin/sh
                          - -c
                          - |
                            apk add --no-cache openssl
                            true | openssl s_client -showcerts -connect gitlab.test:5050 > /usr/local/share/ca-certificates/gitlab.test.crt
                            update-ca-certificates
                            dockerd-entrypoint.sh || exit
                    variables:
                      IMAGE_TAG: "$CI_REGISTRY_IMAGE:$CI_COMMIT_REF_SLUG"
                    script:
                      - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD gitlab.test:5050
                      - docker build -t $IMAGE_TAG .
                      - docker push $IMAGE_TAG
                    tags:
                      - "runner-for-#{project.name}"
                YAML
              }
            ])
          end

          Flow::Pipeline.visit_latest_pipeline

          Page::Project::Pipeline::Show.perform do |pipeline|
            pipeline.click_job('build')
          end

          Page::Project::Job::Show.perform do |job|
            expect(job).to be_successful(timeout: 200)
          end

          Support::Retrier.retry_until(max_duration: 500, sleep_interval: 10) do
            project.pipelines.last[:status] == 'success'
          end

          Page::Project::Menu.perform(&:go_to_container_registry)

          Page::Project::Registry::Show.perform do |registry|
            expect(registry).to have_registry_repository(project.name)

            registry.click_on_image(project.name)

            expect(registry).to have_tag('master')

            registry.click_delete

            expect { registry.has_no_tag?('master') }
              .to eventually_be_truthy.within(max_duration: 60, reload_page: page)
          end
        end
      end
    end
  end
end
