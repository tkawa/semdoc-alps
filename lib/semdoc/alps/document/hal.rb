module Semdoc
  module Alps
    module Document
      class Hal < Base
        # use Halibut::Resource
        private
          def traverse(resource, descriptor, include_obj)
            fqids = traversing_fqids(descriptor)

            traversed_values = resource.properties.slice(*fqids).map do |fqid, value|
              wrap(value, DescriptorStore.lookup(complete_fqid(fqid)))
            end.flatten(1).compact
            link_fqids = resource.links.instance_variable_get(:@relations).keys & fqids
            traversed_links = link_fqids.map do |fqid|
              links = resource.links[fqid]
              wrap(links, DescriptorStore.lookup(complete_fqid(fqid)))
            end.flatten(1).compact
            embedded_resource_fqids = resource.embedded.instance_variable_get(:@relations).keys & fqids
            traversed_embedded_resources = embedded_resource_fqids.map do |fqid|
              embedded_resources = resource.embedded[fqid]
              wrap(embedded_resources, DescriptorStore.lookup(complete_fqid(fqid)))
            end.flatten(1).compact

            traversed_values + traversed_links + traversed_embedded_resources
          end

          def wrap(obj, descriptor)
            case obj
            when Array
              obj.map{|n| wrap(n, descriptor) } # TODO: 再帰じゃなくて1段階だけwrapすればいいはずなんだが
            when Halibut::Core::Resource
              self.class.new(obj, @url, descriptor)
            when Halibut::Core::Link
              obj.extend(ValueWithDescriptor) # TODO: improve
              obj.descriptor = descriptor
              obj.url = obj.href
            else # value
              obj.extend(ValueWithDescriptor) # TODO: improve
              obj.descriptor = descriptor
              obj
            end
          end
      end
    end
  end
end
