require "jekyll-import"

JekyllImport::Importers::Blogger.run({
"source" => "blog.xml",
"no-blogger-info" => false,
"replace-internal-link" => false,
})

