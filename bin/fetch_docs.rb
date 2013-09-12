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

verbose = opts.verbose == true
force_clone = opts.force_clone == true
git_update = opts.git_update == true

cwd = File.expand_path File.dirname(__FILE__)
site_home = cwd + "/../"
puts "Using site home as #{site_home}" if verbose 
cfg = YAML.load_file(site_home + "_config/ispn.yml")

FileUtils.rm_rf site_home + "docs"
FileUtils.rm_rf site_home + "infinispan_srcs" if force_clone
FileUtils.mkdir site_home + "docs"

git_repos = {}

cfg["docs"].each do |ver, ver_cfg|
  FileUtils.mkdir site_home + "docs/" + ver
  git_repos[ver_cfg["github_repo"]] = ver
end

puts "Preparing to generate documentation for #{cfg["docs"].size} versions of Infinispan"
if force_clone
  puts "Cloning #{git_repos.size} git repositories" if verbose
  ## Let's clone some repos!
  git_repos.each do |remote, local| 
    puts "Cloning https://github.com/#{remote}.git into infinispan_srcs/#{local}" if verbose 
    Git.clone("https://github.com/" + remote + ".git", "infinispan_srcs/" + local)
  end
end

if git_update and not force_clone
  puts "Updating git repositories" if verbose
  ## Let's update some repos!
  cfg["docs"].each do |ver, ver_cfg|
    repo = git_repos[ver_cfg["github_repo"]]
    branch = ver_cfg["branch"]
    g = Git.open("infinispan_srcs/" + repo)
    g.checkout branch    
    g.pull
  end
end

## Now lets process each version
cfg["docs"].each do |ver, ver_cfg|
  git_clone = git_repos[ver_cfg["github_repo"]]
  git = Git.open(site_home + "infinispan_srcs/" + git_clone)  
  git.checkout ver_cfg["branch"]
  docs_src = site_home + "infinispan_srcs/" + git_clone + "/" + ver_cfg["location"]
  docs_dest = site_home + "docs/" + ver + "/"
  d = Dir.open docs_src
  d.each {|f| FileUtils.cp_r("#{docs_src}/#{f}", docs_dest, :verbose => verbose) if f != "." and f != ".." and f != "Guardfile"}
end
