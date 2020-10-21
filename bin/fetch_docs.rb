#!/usr/bin/env ruby

require 'yaml'
require 'fileutils'
require 'optimist'

opts = Optimist::options do
  version "fetch_docs 0.0.2 (c) The Infinispan team"
  banner <<-EOS
This script pulls documentation artifacts generated during Infinispan builds
and incorporates them into the Awestruct website.

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
puts "Using site home as #{site_home}" if verbose
cfg = YAML.load_file(site_home + "_config/ispn.yml")

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
  d.each {|f| FileUtils.cp_r("#{docs_src}/#{f}", target, :verbose => verbose) if f != "." and f != ".." and f != "Guardfile"}

  if attr_header != "" then
    puts "Prepending attribute header to .adoc files:\n#{attr_header}"
    Dir.glob("#{target}/**/*.adoc").each {|f|
      basedir = File.dirname(f)
      chapter = File.basename(f).start_with?("chapter")
      incbase = basedir[basedir.index(docbase)..-1]
      file_new = File.open("#{f}.new", "w")
      file_new.puts("#{attr_header}\n")
      file_old = File.open(f, "r")
      file_old.each {|line|
        if chapter then
          file_new.puts(line)
        else
          file_new.puts(line.sub( /include::/, "include::#{incbase}/"))
        end
      }
      file_old.close()
      file_new.close()

      FileUtils.mv file_new.path, file_old.path
    }
  end
end

def extract_maven_artifact(artifact, target)
  puts "Downloading #{artifact} to #{target}"
  %x( mvn org.apache.maven.plugins:maven-dependency-plugin:3.1.1:copy -DoutputDirectory=#{target} -DrepoUrl=https://repository.jboss.org/nexus/content/groups/public-jboss/ -Dartifact=#{artifact} -Dmdep.stripVersion=true)
  %x( unzip -q #{target}/*.zip -d #{target} )
  FileUtils.rm Dir.glob("#{target}/*.zip")
end

def get_maven_docs(htmlArtifact, pdfArtifact, docroot, docbase, docalias)
  target = File.expand_path("#{docroot}/#{docbase}")
  FileUtils.rm_rf target
  FileUtils.mkdir_p target

  extract_maven_artifact(htmlArtifact, target)
  if pdfArtifact != nil then
    extract_maven_artifact(pdfArtifact, target)
  end
  if docalias != nil then
    aliastarget = File.expand_path("#{docroot}/#{docalias}")
    puts "    Alias #{docalias}"
    FileUtils.rm_rf aliastarget
    FileUtils.cp_r(target, aliastarget)
  end
end

Dir.mkdir("#{site_home}/docs/") unless File.exists?("#{site_home}/docs/")
versions_xml_file = File.open("#{site_home}/docs/versions.xml", "w")
versions_xml_file.puts("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
versions_xml_file.puts("<versions>");
cfg["docs"].each do |type, tcfg|
  puts "Processing #{type}"
  tcfg.each do |ver, vcfg|
    puts "  #{ver}"

    attr_header = ""
    asciidocattr = vcfg["asciidocattr"]
    if asciidocattr != nil then
      asciidocattr.each do |attr_name, attr_value|
        attr_header = "#{attr_header}:#{attr_name}: #{attr_value.to_s}\n"
      end
    end

    if type == "infinispan"
      core = vcfg["core"]
      valias = core["alias"]
      get_maven_docs(core["html"], core["pdf"], "#{site_home}/docs", "#{ver}", valias)
      vname = if valias != nil then "#{ver} (#{valias})" else "#{ver}" end
      versions_xml_file.puts("<version name=\"#{vname}\" path=\"#{ver}\" />");
    end
  end
end

# cpp and dotnet clients need the same special treatment
["cpp","dotnet"].each do |client|
  cfg["hotrod"][client]["downloads"].each do |label, artifact|
    if artifact.include?("docs_version")
        docs_version = artifact["docs_version"]
        url = artifact["download"]
        fullname = File.basename(url)
        name = File.basename(url,".zip")
        %x( wget #{url} -O _tmp.zip)
        %x( unzip _tmp.zip "*-Source/documentation/*" -d _tmp)
        %x( mkdir -p _site/hotrod-clients/#{client}/docs )
        %x( rm _tmp/*/documentation/.gitignore )
        %x( mv _tmp/*/documentation "_site/hotrod-clients/#{client}/docs/#{docs_version}" )
        Dir.glob("_site/hotrod-clients/#{client}/docs/**/*.adoc").each do |f|
          %x( asciidoctor #{f} )
        end
        %x( rm -rf _tmp _tmp.zip )
    end
  end
end

# and then it's operator's turn
cfg["ispn_operator"].each do |version, sub|
  puts "#{version} wget"
  zipUrl=sub["zip-url"]
  puts "#{version} wget #{zipUrl}"
  %x( wget #{zipUrl} -O _optmp.zip)
  %x( unzip _optmp.zip "*documentation/*" -d _optmp)
  Dir.glob("_optmp/**/*.asciidoc").each do |f|
    %x( asciidoctor #{f} )
  end
  Dir.glob("_optmp/**/*.html").each do |f|
    %x( cp -r #{f} _optmp )
  end
  %x( mkdir -p _site/infinispan-operator/#{version}/ )
  %x( mv _optmp/*.html "_site/infinispan-operator/#{version}/" )
  %x( mkdir -p _site/infinispan-operator/topics/images/ )
  %x( mv _optmp/*.svg "_site/infinispan-operator/topics/images/" )
  %x( rm -rf _optmp* )
end

# now for the spring boot starter docs
cfg["sb_starter"].each do |version, sub|
  puts "#{version} wget"
  zipUrl=sub["zip-url"]
  puts "#{version} wget #{zipUrl}"
  %x( wget #{zipUrl} -O _sbtmp.zip)
  %x( unzip _sbtmp.zip "*documentation/*" -d _sbtmp)
  Dir.glob("_sbtmp/**/*.asciidoc").each do |f|
    %x( asciidoctor #{f} )
  end
  Dir.glob("_sbtmp/**/*.html").each do |f|
    %x( cp -r #{f} _sbtmp )
  end
  %x( mkdir -p _site/infinispan-spring-boot/#{version}/ )
  %x( mv _sbtmp/*.html "_site/infinispan-spring-boot/#{version}/" )
  %x( rm -rf _sbtmp* )
end

versions_xml_file.puts("</versions>");
versions_xml_file.close()

puts "Time elapsed #{Time.now - beginning} seconds"
