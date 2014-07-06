module Semdoc
  module Alps
    class Document
      attr_reader :data, :url, :origin_descriptor, :profile_urls

      def self.load(url)
        body = DescriptorStore.fetch_document(url)
        body = { 'root' => body } # plain JSON向け対処
        new(body, url)
      end

      def initialize(data, url, origin_descriptor = nil)
        @data = data
        @url = url
        @origin_descriptor = origin_descriptor
        @possible_descriptors = []
        @profile_urls = []
      end

      def apply_profile(profile_url)
        # DescriptorStore.define_profile(profile_url, @url)
        if alps = DescriptorStore.parse(profile_url) # TODO: profile definitionのキャッシュ
          Array.wrap(alps['descriptor']).each do |data_descriptor|
            @possible_descriptors << DescriptorStore.define_leaf_descriptor(data_descriptor, profile_url, @url)
          end
        end
        @profile_urls << profile_url
      end

      def items_for(descriptor_fqid, include_obj = true)
        descriptor = DescriptorStore.lookup(complete_fqid(descriptor_fqid))
        traverse(@data, descriptor, include_obj).compact
      end

      def possible_descriptors
        @origin_descriptor ? @origin_descriptor.subdescriptors : @possible_descriptors
      end

      def inspect
        show_variable_name = %w(@url @origin_descriptor)
        variables_inspect = show_variable_name.map{|n| "#{n}=#{instance_variable_get(n).inspect}" }.join(' ')
        "#<#{self.class}:#{__id__} #{variables_inspect}>"
      end

      private
        def traverse(node, descriptor, include_obj)
          fqids = descriptor.self_and_descendant_fqids
          # 構造を考慮して候補から除く部分。ここがないと子要素全部取る
          possible_fqids = possible_descriptors.map(&:self_and_ancestor_fqids).flatten(1)
          fqids &= possible_fqids
          local_ids = fqids.map{|fqid| fqid.match(/^#{@url}#/).try(:post_match) }.compact
          fqids.concat(local_ids)

          case node
          when Array
            node.map do |child|
              traverse(child, descriptor, include_obj)
            end.flatten(1).compact
          when Hash
            traverse_values = node.slice(*fqids).map do |fqid, value|
              if include_obj
                wrap(value, DescriptorStore.lookup(complete_fqid(fqid)))
              elsif !(value.is_a?(Array) || value.is_a?(Hash))
                value
              else
                nil
              end
            end.flatten(1).compact
            traverse_values.concat(Array(traverse(node.values, descriptor, include_obj)))
          else # value
            []
          end
        end

        def traverse_single(node, descriptor, include_obj)
          # 必要な予感。。。
          # 要素のネストをどれぐらい厳密にとるのか。media typeによるが、looseとstrictの2つ必要な気がする
        end

        def wrap(node, descriptor)
          case node
          when Array
            node.map{|n| wrap(n, descriptor) } # TODO: 再帰じゃなくて1段階だけwrapすればいいはずなんだが
          when Hash
            self.class.new(node, @url, descriptor)
          else
            node
          end
        end

        def complete_fqid(fqid)
          if !fqid.include?('#') # TODO: alias名のときの処理
            "#{url}##{fqid}"
          elsif fqid.start_with?('#')
            "#{url}#{fqid}"
          else
            fqid
          end
        end
    end
  end
end

# Example:
# doc = Semdoc::Alps::Document.load('file:///Users/tkawa/Projects/alps-sample/public/status.json')
# doc.apply_profile('file:///Users/tkawa/Projects/alps-sample/public/status-alps.json')
# postings = doc.items_for("http://alps.io/schema.org/BlogPosting#BlogPosting")
# doc.items_for('text')
# users = doc.items_for('http://alps.io/schema.org/Person#Person')
#
# doc = Semdoc::Alps::Document.load('file:///Users/tkawa/Projects/alps-sample/public/timeline.json')
# doc.apply_profile('file:///Users/tkawa/Projects/alps-sample/public/status-alps.json')
#
# doc = Semdoc::Alps::Document.load('http://localhost:3000/timeline.json')
# doc.apply_profile('http://localhost:3000/status-alps.json')
