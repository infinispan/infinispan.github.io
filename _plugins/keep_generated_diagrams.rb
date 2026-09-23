# asciidoctor-diagram writes generated diagram images (PlantUML SVGs) to the
# site destination during the render phase. Jekyll's cleaner runs after render
# and treats those files as orphaned, deleting them before the write phase.
# Real images in the source tree are unaffected: they are tracked site files
# and never appear in the obsolete list. This hook removes the generated
# images from that list so they survive in _site.
GENERATED_DIAGRAM_IMAGE_RE = %r{/assets/images/blog/[^/]+\.(?:svg|png|jpe?g|gif|webp)\z}

Jekyll::Hooks.register :clean, :on_obsolete do |obsolete|
  obsolete.reject! { |path| path.match?(GENERATED_DIAGRAM_IMAGE_RE) }
end
