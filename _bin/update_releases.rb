#!/usr/bin/env ruby

require "yaml"
require "net/http"
require "uri"
require "json"
require "time"
require "set"

PROJECTS_FILE = File.expand_path("../_data/projects.yml", __dir__)

def github_get(path)
  uri = URI("https://api.github.com#{path}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  req = Net::HTTP::Get.new(uri)
  req["Accept"] = "application/vnd.github+json"
  req["User-Agent"] = "infinispan-website"
  token = ENV["GITHUB_TOKEN"]
  req["Authorization"] = "Bearer #{token}" if token
  res = http.request(req)
  raise "GitHub API #{res.code} for #{path}: #{res.body[0..200]}" unless res.code == "200"
  JSON.parse(res.body)
end

def fetch_releases(owner, repo)
  releases = []
  page = 1
  loop do
    batch = github_get("/repos/#{owner}/#{repo}/releases?per_page=100&page=#{page}")
    break if batch.empty?
    releases.concat(batch)
    break if batch.length < 100
    page += 1
  end
  releases.reject { |r| r["draft"] }
end

# "16.2.0.Dev01" -> "16.2", "15.2.6.Final" -> "15.2"
def minor_version(version_str)
  parts = version_str.to_s.split(".")
  return nil if parts.length < 2
  "#{parts[0]}.#{parts[1]}"
end

# Build the assets map from GitHub release assets.
# Recognizes server and per-platform CLI zips; other .zip assets go under their base name.
def build_assets(gh_assets)
  assets = {}
  cli = {}

  gh_assets.each do |a|
    name = a["name"]
    url = a["browser_download_url"]

    case name
    when /-server-.*\.zip$/
      assets["server"] = url
    when /-cli-.*linux-aarch_64\.zip$/
      cli["linux-aarch64"] = url
    when /-cli-.*linux-x86_64\.zip$/
      cli["linux-x86_64"] = url
    when /-cli-.*osx-aarch_64\.zip$/
      cli["macos-aarch64"] = url
    when /-cli-.*windows-x86_64\.zip$/
      cli["windows-x86_64"] = url
    end
  end

  assets["cli"] = cli unless cli.empty?
  assets.empty? ? nil : assets
end

# Deep-merge: values from +overlay+ are added only when the key is absent in +base+.
# For nested hashes, recurse.
def deep_merge_missing(base, overlay)
  result = base.dup
  overlay.each do |key, value|
    if result.key?(key)
      if result[key].is_a?(Hash) && value.is_a?(Hash)
        result[key] = deep_merge_missing(result[key], value)
      end
      # scalar already present -> keep existing
    else
      result[key] = value
    end
  end
  result
end

# --- main ---

data = YAML.load_file(PROJECTS_FILE)
projects = data["projects"]

projects.each do |project_name, project_cfg|
  github_url = project_cfg["github"]
  next unless github_url

  match = github_url.match(%r{github\.com/([^/]+)/([^/]+)})
  next unless match
  owner, repo = match[1], match[2]

  puts "#{project_name}: fetching releases from #{owner}/#{repo}"

  begin
    releases = fetch_releases(owner, repo)
  rescue => e
    warn "  ERROR: #{e.message}"
    next
  end

  # Find the latest non-prerelease release per minor version
  latest = {}
  releases.reject { |r| r["prerelease"] }.each do |rel|
    ver = rel["tag_name"].sub(/^v/, "")
    mv = minor_version(ver)
    next unless mv
    if latest[mv].nil? || Time.parse(rel["published_at"]) > Time.parse(latest[mv]["published_at"])
      latest[mv] = rel
    end
  end

  # Also include the single latest prerelease (the next upcoming version)
  latest_pre = releases.select { |r| r["prerelease"] }
    .max_by { |r| Time.parse(r["published_at"]) }
  if latest_pre
    ver = latest_pre["tag_name"].sub(/^v/, "")
    mv = minor_version(ver)
    # Only add if this minor version isn't already covered by a stable release
    latest[mv] = latest_pre if mv && !latest.key?(mv)
  end

  # Build a set of existing minor-version keys (as strings) for lookup
  existing_keys = project_cfg.keys.map(&:to_s).to_set

  # Add new minor-version entries and update existing ones
  latest.each do |mv, rel|
    ver = rel["tag_name"].sub(/^v/, "")
    date = Time.parse(rel["published_at"]).strftime("%Y/%m/%d")

    # Use float key if it parses cleanly (e.g. 16.2), otherwise string
    yaml_key = (Float(mv) rescue nil) ? Float(mv) : mv

    unless existing_keys.include?(mv)
      project_cfg[yaml_key] = {}
    end

    entry = project_cfg[yaml_key]

    # Always overwrite these auto-generated fields
    entry["version"] = ver
    entry["release_date"] = date
    entry["release_notes"] = rel["html_url"]

    # Merge assets: new asset URLs are written, but any manually-added asset
    # keys that are not produced by the script are preserved.
    new_assets = build_assets(rel["assets"])
    if new_assets
      if entry["assets"].is_a?(Hash)
        entry["assets"] = deep_merge_missing(new_assets, entry["assets"])
      else
        entry["assets"] = new_assets
      end
    end

    status = existing_keys.include?(mv) ? "updated" : "added"
    puts "  #{mv} -> #{ver} (#{date}) [#{status}]"
  end
end

File.write(PROJECTS_FILE, data.to_yaml)
puts "Wrote #{PROJECTS_FILE}"
