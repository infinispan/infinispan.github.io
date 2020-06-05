module Awestruct
  module Extensions
    module ReadMore
      def truncate(content, url)
        index = content.index("@Read more@")
        if index != nil and index > -1
          content[0..index-1] + "<a href=\"" + url + "\">Read more</a>"
        else
          content
        end
      end
      def filter(content)
        content["@Read more@"] = ""
      end
    end
  end
end

