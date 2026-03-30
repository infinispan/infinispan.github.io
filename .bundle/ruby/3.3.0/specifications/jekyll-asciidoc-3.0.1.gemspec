# -*- encoding: utf-8 -*-
# stub: jekyll-asciidoc 3.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "jekyll-asciidoc".freeze
  s.version = "3.0.1".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/asciidoctor/jekyll-asciidoc/issues", "changelog_uri" => "https://github.com/asciidoctor/jekyll-asciidoc/blob/master/CHANGELOG.adoc", "mailing_list_uri" => "http://discuss.asciidoctor.org", "source_code_uri" => "https://github.com/asciidoctor/jekyll-asciidoc" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Dan Allen".freeze, "Paul Rayner".freeze]
  s.date = "2023-11-06"
  s.description = "A Jekyll plugin that converts the AsciiDoc source files in your site to HTML pages using Asciidoctor.".freeze
  s.email = ["dan.j.allen@gmail.com".freeze]
  s.homepage = "https://github.com/asciidoctor/jekyll-asciidoc".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.6".freeze
  s.summary = "A Jekyll plugin that converts the AsciiDoc source files in your site to HTML pages using Asciidoctor.".freeze

  s.installed_by_version = "3.6.7".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<asciidoctor>.freeze, [">= 1.5.0".freeze, "< 3.0.0".freeze])
  s.add_runtime_dependency(%q<jekyll>.freeze, [">= 3.0.0".freeze])
  s.add_development_dependency(%q<kramdown-parser-gfm>.freeze, ["~> 1.1.0".freeze])
  s.add_development_dependency(%q<pygments.rb>.freeze, ["~> 2.3.0".freeze])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.1.0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.12.0".freeze])
end
