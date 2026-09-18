#!/usr/bin/env ruby

require "net/http"
require "uri"
require "json"

EPICS_FILE = File.expand_path("../_data/epics.yml", __dir__)

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

query = URI.encode_www_form(
  "q" => "repo:infinispan/infinispan is:issue state:open type:Epic",
  "per_page" => "100"
)

epics = github_get("/search/issues?#{query}").fetch("items")
  .sort_by { |i| i["number"] }
  .map do |i|
    {
      "number" => i["number"],
      "title" => i["title"],
      "url" => i["html_url"]
    }
  end

require "yaml"
File.write(EPICS_FILE, epics.to_yaml)
puts "Wrote #{EPICS_FILE} (#{epics.length} epics)"
