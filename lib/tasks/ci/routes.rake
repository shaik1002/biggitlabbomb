# frozen_string_literal: true

namespace :ci do
  namespace :routes do
    desc "GitLab | CI | List routes available to CI_JOB_TOKEN"
    task job_token: :environment do
      puts "| Permission | Resource | Method | Path | Description |"
      puts "| ---------- | -------- | ------ | ---- | ----------- |"
      API::API
        .routes
        .find_all { |r| r.version == "v4" && r.settings.dig(:authentication, :job_token_allowed) }
        .map { |route| formatted(route) }
        .sort
        .each { |row| puts row }
    end

    def description_for(route)
      route.options[:settings][:description][:description] if route.options[:settings][:description]
    end

    def permissions_for(route)
      Array(route.settings.dig(:authentication, :permission))
    end

    def resource_for(route)
      route.settings.dig(:authentication, :resource) || ""
    end

    def formatted(route, delimiter = "|")
      row = [
        permissions_for(route).join(", "),
        resource_for(route),
        route.options[:method],
        route.path,
        description_for(route)
      ].join(" #{delimiter} ")
      "#{delimiter} #{row} #{delimiter}"
    end
  end
end
