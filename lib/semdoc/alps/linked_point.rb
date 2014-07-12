module Semdoc
  module Alps
    class LinkedPoint
      def initialize(url, origin_descriptor)
        @url = url
        @origin = origin_descriptor
      end

      def method_missing(name, *args)
        if @document || Document.instance_methods.include?(name.to_sym)
          @document ||= Document.load(@url)
          _apply_rt_if_necessary
          @document.send(name, *args)
        else
          super # NoMethodError
        end
      end

      def reload!
        @document = Document.load(@url)
      end

      private
        def _apply_rt_if_necessary
          if @origin.rt
            # FIXME: 手抜き実装。descriptor単独で適用できるようにする
            url = @origin.rt.gsub(/\#.*$/, '')
            unless @document.profile_urls.include?(url)
              @document.apply_profile(url)
            end
          end
        end
    end
  end
end
