require 'asciidoctor-diagram/plantuml/converter'

module Jekyll
  module PlantUML
    # Renders a PlantUML diagram to an inline SVG at build time.
    #
    # Usage in Markdown pages:
    #
    #   {% plantuml %}
    #   participant A
    #   participant B
    #   A -> B: hello
    #   {% endplantuml %}
    #
    # The source is wrapped in @startuml/@enduml when missing. Output is a
    # <div class="plantuml-diagram"> containing the SVG. Rendering reuses the
    # single JVM command server shared with the AsciiDoc [plantuml] blocks.
    class Tag < Liquid::Block
      def render(context)
        source = super.strip
        return '' if source.empty?

        code = source.start_with?('@start') ? source : "@startuml\n#{source}\n@enduml"

        response = ::Asciidoctor::Diagram::Java.send_request(
          :url => '/plantuml',
          :body => code,
          :headers => {
            'Accept' => 'image/svg+xml',
            'X-Graphviz' => 'smetana',
            'X-PlantUML-Basedir' => context.registers[:site].source,
          }
        )

        unless response[:code] == 200
          body = response[:body].to_s.dup.force_encoding('UTF-8')
          raise "PlantUML rendering failed (HTTP #{response[:code]}): #{body}"
        end

        # Drop the fixed pixel style so the SVG scales responsively via CSS.
        svg = response[:body].force_encoding('UTF-8')
        svg = svg.sub(%r{(<svg\b[^>]*?)\s+style="[^"]*"}, '\1')
        %(<div class="plantuml-diagram">) + svg + '</div>'
      end
    end
  end
end

Liquid::Template.register_tag('plantuml', Jekyll::PlantUML::Tag)
