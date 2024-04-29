# frozen_string_literal: true

require_relative "lib/gitlab/cng/version"

Gem::Specification.new do |spec|
  spec.name = "gitlab-cng"
  spec.license = "MIT"
  spec.version = Gitlab::Cng::VERSION

  spec.authors = ["GitLab Quality"]
  spec.email = ["quality@gitlab.com"]

  spec.summary = "CNG deployment orchestrator"
  spec.description = "CLI tool to setup environment and deploy CNG builds"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0")

  spec.files = Dir["README.md", "LICENSE.txt", "lib/**/*", "exe/cng"]
  spec.bindir = "exe"
  spec.executables = "cng"
  spec.require_paths = ["lib"]

  spec.add_dependency "require_all", "~> 3.0"
  spec.add_dependency "thor", "~> 1.3"

  spec.add_development_dependency "gitlab-styles", "~> 11.0"
  spec.add_development_dependency "pry", "~> 0.14.2"
  spec.add_development_dependency "rspec", "~> 3.0"
end
