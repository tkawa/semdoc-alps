module Semdoc
  module Alps
    class LinkedPoint
      def initialize(url)
        @url = url
      end

      def method_missing(name, *args)
        if @document || Document.instance_methods.include?(name.to_sym)
          @document ||= Document.load(@url)
          @document.send(name, *args)
        else
          super # NoMethodError
        end
      end

      def reload!
        @document = Document.load(@url)
      end
    end
  end
end
