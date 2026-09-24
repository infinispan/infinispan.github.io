#!/usr/bin/env ruby

require "net/http"
require "uri"
require "json"

ROADMAP_FILE = File.expand_path("../_data/roadmap.yml", __dir__)

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

def fetch_all(q)
  items = []
  page = 1
  loop do
    query = URI.encode_www_form("q" => q, "per_page" => "100", "page" => page.to_s)
    res = github_get("/search/issues?#{query}")
    batch = res.fetch("items")
    items.concat(batch)
    break if batch.size < 100 || items.size >= res["total_count"]
    page += 1
  end
  items
end

issues = (fetch_all("repo:infinispan/infinispan is:issue state:open type:Epic") +
          fetch_all("repo:infinispan/infinispan is:issue state:open type:Feature"))
  .uniq { |i| i["number"] }

roadmap = issues.select do |i|
  (i.fetch("labels", []) || []).any? { |l| l.is_a?(Hash) && l["name"].to_s.start_with?("release/") }
end.sort_by { |i| i["number"] }.map do |i|
    {
      "number" => i["number"],
      "title" => i["title"],
      "url" => i["html_url"]
    }
  end

require "yaml"
File.write(ROADMAP_FILE, roadmap.to_yaml)
puts "Wrote #{ROADMAP_FILE} (#{roadmap.length})"
