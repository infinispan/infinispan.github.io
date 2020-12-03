module Jekyll
  module TagHelpersFilter
    def sort_tags_by_name(tags)
      return tags.map { |k, v| [k, v.size] }
                 .sort_by { |x| [x[0].downcase] }
    end

    def sort_tags_by_posts_count(tags)
      max_posts_count_among_all_tags = tags.max_by { |k, v| v.size }[1].size
      return tags.map { |k, v| [k, v.size] }
                 .sort_by { |x| [max_posts_count_among_all_tags - x[1], x[0].downcase] }
    end
  end
end

Liquid::Template.register_filter(Jekyll::TagHelpersFilter)
