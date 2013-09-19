#!/usr/bin/env ruby
  
require 'yaml'
require 'fileutils'
require 'git'
require 'trollop'

opts = Trollop::options do
  version "fetch_docs 0.0.1 (c) 2013 Manik Surtani"
  banner <<-EOS
This script pulls AsciiDoc documentation from Infnispan repositories (defined
in _config/ispn.yml) and incorporates them into the Awestruct website.

Usage:
       bin/fetch_docs.rb [options]
where [options] are:
EOS

  opt :force_clone, "Force re-clone of documentation repos", :default => false
  opt :verbose, "Be verbose", :default => false
  opt :git_update, "Will update documentation from git, if force-clone is not set", :default => false
end

beginning = Time.now

verbose = opts.verbose == true
force_clone = opts.force_clone == true
git_update = opts.git_update == true

cwd = File.expand_path File.dirname(__FILE__)
site_home = cwd + "/../"
puts "Using site home as #{site_home}" if verbose 
cfg = YAML.load_file(site_home + "_config/ispn.yml")

FileUtils.rm_rf site_home + "docs"

def get_docs(repo, branch, loc, target, verbose)  
  FileUtils.mkdir_p target
  puts "    Cloning #{repo}@#{branch}/#{loc} to #{target}" if verbose
  tmp = "/tmp/fetchdocs"
  FileUtils.rm_rf tmp
  Git.clone(repo, tmp)
  g = Git.open(tmp)
  g.checkout branch    

  docs_src = "#{tmp}/#{loc}"
  d = Dir.open docs_src
  d.each {|f| FileUtils.cp_r("#{docs_src}/#{f}", target, :verbose => verbose) if f != "." and f != ".." and f != "Guardfile"}
  FileUtils.rm_rf tmp
end

cfg["docs"].each do |type, tcfg|
  puts "Processing #{type}"
  tcfg.each do |ver, vcfg|
    puts "  #{ver}"
    if type == "infinispan"
      core = vcfg["core"]
      server = vcfg["server"]

      get_docs(core["git_repo"], core["branch"], core["location"], "#{site_home}docs/#{ver}", verbose)
      get_docs(server["git_repo"], server["branch"], server["location"], "#{site_home}docs/#{ver}", verbose) if server != nil

    elsif type == "cachestores"
      cs_name = ver
      get_docs(vcfg["git_repo"], vcfg["branch"], vcfg["location"], "#{site_home}docs/#{type}/#{cs_name}", verbose)

    elsif type == "hotrod-clients"
      hrc_name = ver
      get_docs(vcfg["git_repo"], vcfg["branch"], vcfg["location"], "#{site_home}docs/#{type}/#{hrc_name}", verbose)

    end
  end
end

puts "Time elapsed #{Time.now - beginning} seconds"
