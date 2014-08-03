require 'semdoc/alps/document/base'
require 'semdoc/alps/document/hal'
require 'semdoc/alps/document/uber'

module Semdoc
  module Alps
    module Document
      MIME_TYPE = {
        json:     'application/json',
        haljson:  'application/hal+json',
        halxml:   'application/hal+xml',
        uberjson: 'application/vnd.amundsen-uber+json'
      }.freeze

      def self.load(url, supposed_mime_type = :json)
        body = DescriptorStore.fetch_document(url, accept: MIME_TYPE[supposed_mime_type])
        # TODO: Linkヘッダからprofileを適用
        case supposed_mime_type
        when :json
          body = { 'root' => body } # plain JSON向け対処
          self::Base.new(body, url)
        when :haljson, :halxml
          json = MultiJson.dump(body) # FIXME: 手抜き
          resource = Halibut::Adapter::JSON.parse(json)
          self::Hal.new(resource, url).tap do |doc| # TODO: better to apply in initializer
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
        when :uberjson
          uber = Uberous::Loader.new(body).uber
          self::Uber.new(uber, url)
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
