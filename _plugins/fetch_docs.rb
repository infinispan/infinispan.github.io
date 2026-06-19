#!/usr/bin/env ruby

require "yaml"
require "fileutils"
require "optimist"
require "nokogiri"

MVN_DEPENDENCY_PLUGIN = "org.apache.maven.plugins:maven-dependency-plugin:3.11.0"

opts = Optimist::options do
  version "fetch_docs 0.2.0 (c) The Infinispan team"
  banner <<-EOS
This script pulls documentation artifacts generated during Infinispan builds
and incorporates them into the website.
Usage:
       bin/fetch_docs.rb [options]
where [options] are:
EOS

  opt :verbose, "Be verbose", :default => false
end

beginning = Time.now

verbose = opts.verbose == true

cwd = File.expand_path File.dirname(__FILE__)
site_home = cwd + "/../"
puts "Using the docs directory" if verbose
projects = YAML.load_file("_data/projects.yml")

def get_docs(tmp, name, repo, branch, loc, docroot, docbase, verbose, attr_header)
  target = File.expand_path("#{docroot}#{docbase}")
  FileUtils.mkdir_p target
  puts "    Cloning #{repo}/#{loc} to #{target}" if verbose
  git_clone_path = "#{tmp}/#{name}"
  %x( git clone --depth=1 #{repo} #{git_clone_path} 2>&1 > /dev/null )
  oldwd = FileUtils.pwd
  FileUtils.chdir git_clone_path
  puts "    Fetching branch #{branch}" if verbose
  %x( git fetch --depth=1 origin #{branch} 2>&1 > /dev/null )
  %x( git checkout FETCH_HEAD 2>&1 > /dev/null  )
  FileUtils.chdir oldwd

  docs_src = "#{git_clone_path}/#{loc}"
  d = Dir.open docs_src
  d.each { |f| FileUtils.cp_r("#{docs_src}/#{f}", target, :verbose => verbose) if f != "." and f != ".." and f != "Guardfile" }

  if attr_header != ""
    puts "Prepending attribute header to .adoc files:\n#{attr_header}"
    Dir.glob("#{target}/**/*.adoc").each { |f|
      basedir = File.dirname(f)
      chapter = File.basename(f).start_with?("chapter")
      incbase = basedir[basedir.index(docbase)..-1]
      file_new = File.open("#{f}.new", "w")
      file_new.puts("#{attr_header}\n")
      file_old = File.open(f, "r")
      file_old.each { |line|
        if chapter
          file_new.puts(line)
        else
          file_new.puts(line.sub(/include::/, "include::#{incbase}/"))
        end
      }
      file_old.close()
      file_new.close()

      FileUtils.mv file_new.path, file_old.path
    }
  end
end

def injectAnalytics(target)
   cwd = File.expand_path File.dirname(__FILE__)
   puts "Injecting analytics into #{target}"
   sed_i = RUBY_PLATFORM =~ /darwin/ ? "sed -i ''" : "sed -i"
   %x( find #{target} -name "*.html" -exec #{sed_i} -f #{cwd}/inject-analytics.sed '{}' '\;' )
end

def extract_maven_artifact(artifact, target, ext)
  puts "Downloading #{artifact} to #{target}"
  %x( mvn #{MVN_DEPENDENCY_PLUGIN}:copy -DoutputDirectory=#{target} -DrepoUrl=https://search.maven.org/artifact/ -Dartifact=#{artifact} -Dmdep.stripVersion=true)
  %x( unzip -qo #{target}/*#{ext} -d #{target} )
  FileUtils.rm Dir.glob("#{target}/*#{ext}")
end

def get_maven_docs(htmlArtifact, javadocArtifact, pdfArtifact, docroot, docbase, docalias)
  target = File.expand_path("#{docroot}/#{docbase}")
  FileUtils.rm_rf target
  FileUtils.mkdir_p target

  extract_maven_artifact(htmlArtifact, target, ".zip")
  if javadocArtifact != nil
    extract_maven_artifact(javadocArtifact, "#{target}/apidocs", ".jar")
    unless ENV.fetch("SKIP_ANALYTICS_INJECTION", "false").upcase == "TRUE"
      injectAnalytics("#{target}/apidocs")
    else
      puts "Skipping analytics injection for #{target}/apidocs (SKIP_ANALYTICS_INJECTION=true)"
    end
  end
  if pdfArtifact != nil
    extract_maven_artifact(pdfArtifact, target, ".zip")
  end

  if docalias != nil
    aliastarget = File.expand_path("#{docroot}/#{docalias}")
    puts "    Alias #{docalias}"
    FileUtils.rm_rf aliastarget
    FileUtils.cp_r(target, aliastarget)
  end
end

def gen_versions_xml_file(filePath, sourceData)
  xmlVersionBuilder = Nokogiri::XML::Builder.new(:encoding => "UTF-8") do |xml|
    xml.versions {
      sourceData.each do |sourceData|
        if sourceData.include? "!"
          xml.version("name" => sourceData.split("!").first, "path" => sourceData.split("!").last)
        else
          xml.version("name" => sourceData, "path" => sourceData)
        end
      end
    }
  end
  File.write(filePath, xmlVersionBuilder.to_xml)
end

def minor_to_s(minor)
  minor.is_a?(Float) ? format("%.1f", minor) : minor.to_s
end

def fetch_github_docs(github_url, branch, target_dir, verbose)
  zip_url = "#{github_url}/archive/#{branch}.zip"
  tmp_prefix = File.basename(target_dir)
  %x( wget -q #{zip_url} -O _#{tmp_prefix}tmp.zip)
  %x( unzip -o _#{tmp_prefix}tmp.zip "*documentation/*" -d _#{tmp_prefix}tmp)
  Dir.glob("_#{tmp_prefix}tmp/**/*.{asciidoc,adoc}").each do |f|
    %x( asciidoctor #{f} )
  end
  Dir.glob("_#{tmp_prefix}tmp/**/*.html").each do |f|
    %x( cp -r #{f} _#{tmp_prefix}tmp )
  end
  FileUtils.mkdir_p target_dir
  %x( mv _#{tmp_prefix}tmp/*.html "#{target_dir}/" )
  %x( rm -rf _#{tmp_prefix}tmp* )
end

forceDocumentationDownload = (ENV.fetch("FORCE_DOCUMENTATION_DOWNLOAD") { "true" }).upcase
if forceDocumentationDownload == "FALSE" and File.file?("docs/versions.xml")
  puts "Documentation exists. Skip the forced download..."
else
  FileUtils.rm_rf(Dir.glob("docs/*"))
  Dir.mkdir("docs/") unless File.directory?("docs/")
  coreDocIndex = Array.new
  operatorDocIndex = Array.new
  helmChartDocIndex = Array.new

  # Fetch infinispan core docs
  infinispan = projects["projects"]["infinispan"]
  infinispan.each do |minor, cfg|
    next if minor == "github"
    next unless cfg.is_a?(Hash)
    next unless cfg["alias"] || cfg["docs"]

    version = cfg["version"]
    valias = cfg["alias"]
    minor_str = minor_to_s(minor)
    doc_dir = "#{minor_str}.x"

    puts "Processing infinispan #{doc_dir}"

    html_artifact = "org.infinispan:infinispan-docs:#{version}:zip:html"
    javadoc_artifact = cfg.fetch("docs_javadoc", true) ? "org.infinispan:infinispan-javadoc-all:#{version}:jar:javadoc" : nil

    get_maven_docs(html_artifact, javadoc_artifact, nil, "docs", doc_dir, valias)
    vname = if valias != nil then "#{doc_dir} (#{valias})" else doc_dir end
    coreDocIndex.push "#{vname}!#{doc_dir}"
    %x( mvn #{MVN_DEPENDENCY_PLUGIN}:unpack -DoutputDirectory=schemas -DmarkersDirectory=. -Dartifact=org.infinispan:infinispan-distribution:#{version}:zip:xsd )
    if Gem::Version.new(version.sub(".Final", "")) >= Gem::Version.new("16.2.1")
      %x( mvn #{MVN_DEPENDENCY_PLUGIN}:unpack -DoutputDirectory=schemas -DmarkersDirectory=. -Dartifact=org.infinispan:infinispan-distribution:#{version}:zip:json )
      if valias == "stable"
        Dir.glob("schemas/*-#{minor_str}.json").each do |f|
          unversioned = f.sub("-#{minor_str}.json", ".json")
          FileUtils.cp(f, unversioned)
        end
      end
    end
  end

  # Fetch simple tutorials
  tutorials = projects["projects"]["simple-tutorials"]
  if tutorials && tutorials["doc_branches"]
    tutorials["doc_branches"].each do |branch|
      fetch_github_docs(tutorials["github"], branch, "tutorials/simple", verbose)
    end
  end

  # Fetch Hot Rod client docs
  {"js-client" => "js", "cpp-client" => "cpp", "dotnet-client" => "dotnet", "go-client" => "go"}.each do |client, short_name|
    project = projects["projects"][client]
    next unless project && project["doc_branches"]
    project["doc_branches"].each do |branch|
      fetch_github_docs(project["github"], branch, "docs/hotrod-clients/#{short_name}/latest", verbose)
    end
  end

  # Fetch operator docs
  operator = projects["projects"]["operator"]
  if operator && operator["doc_branches"]
    operator["doc_branches"].each do |branch|
      zip_url = "#{operator["github"]}/archive/#{branch}.zip"
      %x( wget -q #{zip_url} -O _optmp.zip)
      %x( unzip -o _optmp.zip "*documentation/*" -d _optmp)
      Dir.glob("_optmp/**/*.asciidoc").each do |f|
        %x( asciidoctor #{f} )
      end
      Dir.glob("_optmp/**/*.html").each do |f|
        %x( cp -r #{f} _optmp )
      end
      %x( mkdir -p docs/infinispan-operator/#{branch}/ )
      %x( mkdir -p docs/infinispan-operator/topics/images/ )
      %x( mv _optmp/*.html _optmp/**/documentation/asciidoc/css _optmp/**/documentation/asciidoc/js "docs/infinispan-operator/#{branch}/" )
      # Use images only on main. Causes harmless "cannot stat" messages.
      if branch == "main"
        %x( cp -r _optmp/infinispan-operator-main/documentation/asciidoc/topics/images/* "docs/infinispan-operator/topics/images/" )
      end
      %x( rm -rf _optmp* )
      operatorDocIndex.push branch
    end
  end

  # Fetch Helm chart docs
  helm = projects["projects"]["helm-charts"]
  if helm && helm["doc_branches"]
    helm["doc_branches"].each do |branch|
      zip_url = "#{helm["github"]}/archive/#{branch}.zip"
      %x( wget -q #{zip_url} -O _charttmp.zip)
      %x( unzip -o _charttmp.zip "*documentation/*" -d _charttmp)
      Dir.glob("_charttmp/**/*.asciidoc").each do |f|
        %x( asciidoctor #{f} )
      end
      Dir.glob("_charttmp/**/*.html").each do |f|
        %x( cp -r #{f} _charttmp )
      end
      %x( mkdir -p docs/helm-chart/#{branch}/ )
      %x( mv _charttmp/*.html _charttmp/**/documentation/asciidoc/css _charttmp/**/documentation/asciidoc/js "docs/helm-chart/#{branch}/" )
      %x( rm -rf _charttmp* )
      helmChartDocIndex.push branch
    end
  end

  gen_versions_xml_file("docs/infinispan-operator/versions.xml", operatorDocIndex)
  gen_versions_xml_file("docs/helm-chart/versions.xml", helmChartDocIndex)
  gen_versions_xml_file("docs/versions.xml", coreDocIndex)

  sed_i = RUBY_PLATFORM =~ /darwin/ ? "sed -i ''" : "sed -i"
  system("find . -regex \"\\./docs/[0-9].*html$\" -exec #{sed_i} -e \"s|^<head>$|<head><meta name=\\\"robots\\\" content=\\\"noindex\\\">|\" {} \\;")
  system("find . -regex \"\\./docs/infinispan-operator/[0-9].*html$\" -exec #{sed_i} -e \"s|^<head>$|<head><meta name=\\\"robots\\\" content=\\\"noindex\\\">|\" {} \\;")
end
puts "Time elapsed #{Time.now - beginning} seconds"
