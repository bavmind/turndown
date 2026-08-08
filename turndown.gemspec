# frozen_string_literal: true

require_relative "lib/turndown/version"

Gem::Specification.new do |spec|
  spec.name = "turndown"
  spec.version = Turndown::VERSION
  spec.authors = ["Devran Cosmo Uenal"]
  spec.email = ["devran@bavmind.com"]

  spec.summary = "Convert HTML to Markdown. An unofficial Ruby port of Turndown."
  spec.description = <<~DESC.gsub("\n", " ").strip
    A Nokogiri-backed Ruby port of Turndown and turndown-plugin-gfm, verified
    against the upstream fixture corpus. Unofficial and not affiliated with the
    upstream JavaScript project.
  DESC

  spec.homepage = "https://github.com/bavmind/turndown"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "#{spec.homepage}/tree/v#{spec.version}",
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "rubygems_mfa_required" => "true"
  }

  # Ship everything under lib/, not just .rb, so future non-Ruby assets are not
  # silently left out of the gem. Dotfiles (.DS_Store and friends) are excluded.
  spec.files = Dir.glob("lib/**/*").select do |path|
    File.file?(path) && !File.basename(path).start_with?(".")
  end + %w[LICENSE README.md CHANGELOG.md]
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri", ">= 1.16"
end
