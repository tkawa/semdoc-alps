require 'semdoc/alps/document/base'
require 'semdoc/alps/document/hal'

module Semdoc
  module Alps
    module Document
      def self.load(url, supposed_mime_type = :json)
        body = DescriptorStore.fetch_document(url)
        # TODO: Linkヘッダからprofileを適用
        case supposed_mime_type
        when :json
          body = { 'root' => body } # plain JSON向け対処
          self::Base.new(body, url)
        when :jsonhal, :xmlhal
          json = MultiJson.dump(body) # FIXME: 手抜き
          resource = Halibut::Adapter::JSON.parse(json)
          self::Hal.new(resource, url).tap do |doc|
            if links = resource.links['profile']
              links.each do |link|
                doc.apply_profile(link.href)
              end
            end
            # typeが複数ある場合たぶんうまくいかない
            if links = resource.links['type']
              links.each do |link|
                doc.apply_profile(link.href, as_root: true)
              end
            end
          end
        else
          raise NotImplementedError, supposed_mime_type
        end
      end
    end

    module ValueWithDescriptor
      def descriptor;     @_descriptor     end
      def descriptor=(v); @_descriptor = v end
      def url;            @_url            end
      def url=(v);        @_url = v        end
    end
  end
end
