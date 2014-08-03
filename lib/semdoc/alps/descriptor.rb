module Semdoc
  module Alps
    class Descriptor
      attr_reader :namespace, :parent, :children, :subdescriptors

      def initialize(namespace: '', short_id: nil, type: nil, rt: nil, parent: nil, children: [])
        @namespace = namespace
        @short_id = short_id
        @type = type
        @rt = rt
        set_parent(parent)
        @children = children
        @subdescriptors = []
      end

      def set_parent(parent_descriptor)
        @parent = parent_descriptor
        parent_descriptor.children << self if parent_descriptor
      end
      private :set_parent

      def descendants
        children.map(&:self_and_descendants).flatten(1)
      end

      def descendant_fqids
        descendants.map(&:fqid)
      end

      def self_and_descendants
        descendants.unshift(self)
      end

      def self_and_descendant_fqids
        descendant_fqids.unshift(fqid)
      end

      def ancestors
        parent ? parent.ancestors.unshift(parent) : []
      end

      def ancestor_fqids
        ancestors.map(&:fqid)
      end

      def self_and_ancestors
        ancestors.unshift(self)
      end

      def self_and_ancestor_fqids
        ancestor_fqids.unshift(fqid)
      end

      def short_id
        @short_id || @parent.try(:short_id)
      end

      def fqid
        "#{namespace}##{short_id}"
      end

      def type
        @type || @parent.try(:type)
      end

      def rt
        @rt || @parent.try(:rt)
      end

      def inspect
        show_variable_name = %w(@namespace @short_id @type @rt)
        variables_inspect = show_variable_name.map{|n| "#{n}=#{instance_variable_get(n).inspect}" }.join(' ')
        "#<#{self.class}:#{__id__} #{variables_inspect}>"
      end
    end

    class OrphanedLeafDescriptor < Descriptor
      # TODO: 操作の際、Orphanedになっていないdescriptorがあれば探して差し替える
    end
  end
end
