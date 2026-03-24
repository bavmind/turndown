require_relative "lib/turndown/version"

Gem::Specification.new do |spec|
  spec.name = "turndown-ruby"
  spec.version = Turndown::VERSION
  spec.authors = ["OpenAI Codex"]
  spec.email = ["codex@openai.com"]

  spec.summary = "A Ruby port of Turndown for converting HTML to Markdown."
  spec.description = "A Nokogiri-backed Ruby gem that ports Turndown and its GFM plugin with Ruby idioms."
  spec.homepage = "https://github.com/mixmark-io/turndown"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.glob("{lib,test}/**/*", File::FNM_DOTMATCH).reject do |path|
    File.directory?(path) || path.end_with?(".DS_Store")
  end + %w[Gemfile LICENSE README.md REFACTOR.md Rakefile turndown-ruby.gemspec]
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri", ">= 1.16"

  spec.add_development_dependency "minitest", ">= 5.20"
  spec.add_development_dependency "rake", ">= 13.0"
end
