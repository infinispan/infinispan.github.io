require 'asciidoctor'
require 'asciidoctor/extensions'
require 'awestruct/handlers/template/asciidoc'

# Monkeypatch the AsciidoctorTemplate class from Awestruct to register Asciidoctor::Document object in page context.
# Remove this hack when issue [1] will be resolved and available in a release.
# [1] https://github.com/awestruct/awestruct/issues/288
class Awestruct::Tilt::AsciidoctorTemplate
  def evaluate(scope, locals)
    @output ||= (scope.document = ::Asciidoctor.load(data, options)).convert
  end
end

#require 'open-uri/cached'
#OpenURI::Cache.cache_path = ::File.join Awestruct::Engine.instance.config.dir, 'vendor', 'uri-cache'

Asciidoctor::Extensions.register do
  current_doc = @document

  # workaround lack of docfile support for Asciidoctor base_dir option in Awestruct
  if (docfile = current_doc.attributes['docfile'])
    current_doc.instance_variable_set :@base_dir, (File.dirname docfile)
  end
end

module Awestruct
  class Engine
    def production?
      site.profile == 'production'
    end

    def development?
      site.profile == 'development'
    end

    def generate_on_access?
      site.config.options.generate_on_access
    end
  end
end

