module Semdoc
  module Alps
    module Document
      class Uber < Base
        def main_data
          # should be `link_for('self')`
          self_data = @data.data_collection.find{|data| data.rel == 'self' }
          self_url = self_data.url ? resolve_alps_url(self_data.url) : @url
          self.class.new(self_data, self_url, self_data.name)
        end

        def profile_urls
          @data.data_collection.map{|data| data.url if data.rel == 'profile' }.compact
        end

        # use Uberous::Uber and Uberous::Data
        private
          def traverse(uber, descriptor, include_obj)
            if uber.is_a?(Uberous::Uber)
              uber.data_collection.map do |data|
                traverse_data(data, descriptor, include_obj)
              end.flatten(1).compact
              # TODO: process error_data
            else # Uberous::Data
              traverse_data(uber, descriptor, include_obj)
            end
          end

          def traverse_data(data, descriptor, include_obj)
            fqids = traversing_fqids(descriptor)

            traversed =
              if include_obj || data.value
                if fqids.include?(data.name)
                  wrap(data, data.name)
                elsif fqids.include?(data.rel)
                  wrap(data, data.rel)
                end
              end

            traversed_children = data.data_collection.map do |child_data|
              traverse_data(child_data, descriptor, include_obj)
            end.flatten(1).compact

            Array(traversed) + traversed_children
          end

          # def traverse_error_data(data, descriptor, include_obj)
          # end

          def wrap(data, name_or_rel)
            descriptor = lookup_descriptor(name_or_rel)
            if data.value
              value = data.value.dup
              value.extend(ValueWithDescriptor) # TODO: improve
              value.descriptor = descriptor
              value
            else # data itself
              data_url = data.url ? resolve_alps_url(data.url) : @url
              data_descriptor = data.name ? lookup_descriptor(data.name) : descriptor # nameを優先する
              self.class.new(data, data_url, data_descriptor)
            end
          end
      end
    end
  end
end
