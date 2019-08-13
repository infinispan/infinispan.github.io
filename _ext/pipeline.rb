require 'wget_wrapper'
require 'js_minifier'
require 'css_minifier'
require 'html_minifier'
require 'file_merger'
require 'less_config'
require 'awestruct_ext'
require 'asciidoc'

Awestruct::Extensions::Pipeline.new do
  helper Awestruct::Extensions::Partial
  extension Awestruct::Extensions::WgetWrapper.new
  transformer Awestruct::Extensions::JsMinifier.new
  transformer Awestruct::Extensions::CssMinifier.new
  transformer Awestruct::Extensions::HtmlMinifier.new
  extension Awestruct::Extensions::FileMerger.new
  extension Awestruct::Extensions::LessConfig.new
  extension Awestruct::Extensions::Posts.new( '/blog', :posts )
  extension Awestruct::Extensions::Paginator.new( :posts, '/blog/index', :per_page => 5 )
  extension Awestruct::Extensions::Tagger.new( :posts, '/blog/index', '/blog/tags', :per_page => 10 )
  extension Awestruct::Extensions::TagCloud.new( :tagcloud, '/blog/tags/index.html', :layout=>'project', :title=>'Tags')
  extension Awestruct::Extensions::Indexifier.new([/^\/docs\/.*/, /\/404.html/]) # Exclude generated docs from "Indexification"
  extension Awestruct::Extensions::Atomizer.new( :posts, '/feed.atom', :feed_title=>'Infinispan' )
  helper Awestruct::Extensions::GoogleAnalytics
end
