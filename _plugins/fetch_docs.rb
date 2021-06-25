#!/usr/bin/env ruby

require "yaml"
require "fileutils"
require "optimist"
require "nokogiri"

opts = Optimist::options do
  version "fetch_docs 0.1.0 (c) The Infinispan team"
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
puts "Using the docs directory" if verbose
cfg = YAML.load_file("_data/ispn.yml")

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

def extract_maven_artifact(artifact, target)
  puts "Downloading #{artifact} to #{target}"
  %x( mvn org.apache.maven.plugins:maven-dependency-plugin:3.1.1:copy -DoutputDirectory=#{target} -DrepoUrl=https://search.maven.org/artifact/ -Dartifact=#{artifact} -Dmdep.stripVersion=true)
  %x( unzip -q #{target}/*.zip -d #{target} )
  FileUtils.rm Dir.glob("#{target}/*.zip")
end

def get_maven_docs(htmlArtifact, pdfArtifact, docroot, docbase, docalias)
  target = File.expand_path("#{docroot}/#{docbase}")
  FileUtils.rm_rf target
  FileUtils.mkdir_p target

  extract_maven_artifact(htmlArtifact, target)
  if pdfArtifact != nil
    extract_maven_artifact(pdfArtifact, target)
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

forceDocumentationDownload = (ENV.fetch("FORCE_DOCUMENTATION_DOWNLOAD") { "true" }).upcase
if forceDocumentationDownload == "FALSE" and File.exists?("docs/versions.xml")
  puts "Documentation exists. Skip the forced download..."
else
  FileUtils.rm_rf(Dir.glob("docs/*"))
  Dir.mkdir("docs/") unless File.exists?("docs/")
  coreDocIndex = Array.new
  operatorDocIndex = Array.new

  cfg["docs"].each do |type, tcfg|
    puts "Processing #{type}"
    tcfg.each do |ver, vcfg|
      puts "  #{ver}"

      attr_header = ""
      asciidocattr = vcfg["asciidocattr"]
      if asciidocattr != nil
        asciidocattr.each do |attr_name, attr_value|
          attr_header = "#{attr_header}:#{attr_name}: #{attr_value.to_s}\n"
        end
      end

      if type == "infinispan"
        core = vcfg["core"]
        valias = core["alias"]
        get_maven_docs(core["html"], core["pdf"], "docs", "#{ver}", valias)
        vname = if valias != nil then "#{ver} (#{valias})" else "#{ver}" end
        coreDocIndex.push "#{vname}!#{ver}"
      end
    end
  end

  # cpp and dotnet clients need the same special treatment
  ["cpp", "dotnet"].each do |client|
    cfg["hotrod"][client]["downloads"].each do |label, artifact|
      if artifact.include?("docs_version")
        docs_version = artifact["docs_version"]
        url = artifact["download"]
        fullname = File.basename(url)
        name = File.basename(url, ".zip")
        %x( wget #{url} -O _tmp.zip)
        %x( unzip _tmp.zip "*-Source/documentation/*" -d _tmp)
        %x( mkdir -p docs/hotrod-clients/#{client}/docs )
        %x( rm _tmp/*/documentation/.gitignore )
        %x( mv _tmp/*/documentation "docs/hotrod-clients/#{client}/docs/#{docs_version}" )
        Dir.glob("docs/hotrod-clients/#{client}/docs/**/*.adoc").each do |f|
          %x( asciidoctor #{f} )
        end
        %x( rm -rf _tmp _tmp.zip )
      end
    end
  end

  # Hot Rod JS client latest
  cfg["hr_js_client"].each do |version, sub|
    puts "#{version} wget"
    zipUrl = sub["zip-url"]
    puts "#{version} wget #{zipUrl}"
    %x( wget #{zipUrl} -O _jstmp.zip)
    %x( unzip _jstmp.zip "*documentation/*" -d _jstmp)
    Dir.glob("_jstmp/**/*.asciidoc").each do |f|
      %x( asciidoctor #{f} )
    end
    Dir.glob("_jstmp/**/*.html").each do |f|
      %x( cp -r #{f} _jstmp )
    end
    %x( mkdir -p docs/hotrod-clients/js/latest/ )
    %x( mv _jstmp/*.html "docs/hotrod-clients/js/latest/" )
    %x( rm -rf _jstmp* )
    operatorDocIndex.push "main"
  end

  # Hot Rod C++ client latest
  cfg["hr_cpp_client"].each do |version, sub|
    puts "#{version} wget"
    zipUrl = sub["zip-url"]
    puts "#{version} wget #{zipUrl}"
    %x( wget #{zipUrl} -O _cpptmp.zip)
    %x( unzip _cpptmp.zip "*documentation/*" -d _cpptmp)
    Dir.glob("_cpptmp/**/*.asciidoc").each do |f|
      %x( asciidoctor #{f} )
    end
    Dir.glob("_cpptmp/**/*.html").each do |f|
      %x( cp -r #{f} _cpptmp )
    end
    %x( mkdir -p docs/hotrod-clients/cpp/latest/ )
    %x( mv _cpptmp/*.html "docs/hotrod-clients/cpp/latest/" )
    %x( rm -rf _cpptmp* )
    operatorDocIndex.push "main"
  end

  # Hot Rod .NET/C# client latest
  cfg["hr_dotnet_client"].each do |version, sub|
    puts "#{version} wget"
    zipUrl = sub["zip-url"]
    puts "#{version} wget #{zipUrl}"
    %x( wget #{zipUrl} -O _dotnettmp.zip)
    %x( unzip _dotnettmp.zip "*documentation/*" -d _dotnettmp)
    Dir.glob("_dotnettmp/**/*.asciidoc").each do |f|
      %x( asciidoctor #{f} )
    end
    Dir.glob("_dotnettmp/**/*.html").each do |f|
      %x( cp -r #{f} _dotnettmp )
    end
    %x( mkdir -p docs/hotrod-clients/dotnet/latest/ )
    %x( mv _dotnettmp/*.html "docs/hotrod-clients/dotnet/latest/" )
    %x( rm -rf _dotnettmp* )
    operatorDocIndex.push "main"
  end

  # and then it's operator's turn
  cfg["ispn_operator"].each do |version, sub|
    puts "#{version} wget"
    zipUrl = sub["zip-url"]
    puts "#{version} wget #{zipUrl}"
    %x( wget #{zipUrl} -O _optmp.zip)
    %x( unzip _optmp.zip "*documentation/*" -d _optmp)
    Dir.glob("_optmp/**/*.asciidoc").each do |f|
      %x( asciidoctor #{f} )
    end
    Dir.glob("_optmp/**/*.html").each do |f|
      %x( cp -r #{f} _optmp )
    end
    %x( mkdir -p docs/infinispan-operator/#{version}/ )
    %x( mkdir -p docs/infinispan-operator/topics/images/ )
    %x( mv _optmp/*.html _optmp/**/documentation/asciidoc/css _optmp/**/documentation/asciidoc/js "docs/infinispan-operator/#{version}/" )
    #Use images only on main. Causes harmless "cannot stat" messages.
    %x( cp -r _optmp/infinispan-operator-main/documentation/asciidoc/topics/images/* "docs/infinispan-operator/topics/images/" )
    %x( rm -rf _optmp* )
    operatorDocIndex.push "#{version}"
  end

  # now for the spring boot starter docs
  cfg["sb_starter"].each do |version, sub|
    puts "#{version} wget"
    zipUrl = sub["zip-url"]
    puts "#{version} wget #{zipUrl}"
    %x( wget #{zipUrl} -O _sbtmp.zip)
    %x( unzip _sbtmp.zip "*documentation/*" -d _sbtmp)
    Dir.glob("_sbtmp/**/*.asciidoc").each do |f|
      %x( asciidoctor #{f} )
    end
    Dir.glob("_sbtmp/**/*.html").each do |f|
      %x( cp -r #{f} _sbtmp )
    end
    %x( mkdir -p docs/infinispan-spring-boot/#{version}/ )
    %x( mv _sbtmp/*.html "docs/infinispan-spring-boot/#{version}/" )
    %x( rm -rf _sbtmp* )
  end

  gen_versions_xml_file("docs/infinispan-operator/versions.xml", operatorDocIndex)
  gen_versions_xml_file("docs/versions.xml", coreDocIndex)
end

puts "Time elapsed #{Time.now - beginning} seconds"
