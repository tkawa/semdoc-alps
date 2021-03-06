module Semdoc
  module Alps
    module Document
      class Base
        attr_reader :data, :url, :origin_descriptor, :applied_profile_urls

        def initialize(data, url, origin_descriptor = nil)
          @data = data
          @url = url # absolute URL
          @origin_descriptor = origin_descriptor # TODO: 複数個の可能性も
          @possible_descriptors = []
          @applied_profile_urls = []
          profile_urls.each do |profile_url|
            apply_profile(profile_url)
          end
        end

        def profile_urls
          # should override
          []
        end

        def apply_profile(profile_url, as_root: false)
          profile_url = resolve_alps_url(profile_url)
          puts "Already applied: #{profile_url}" and return if @applied_profile_urls.include?(profile_url)
          puts "Apply#{' as root' if as_root}: #{profile_url}"
          if alps = DescriptorStore.parse(profile_url)
            Array.wrap(alps['descriptor']).each do |data_descriptor|
              leaf_descriptor = DescriptorStore.define_leaf_descriptor(data_descriptor, profile_url, @url)
              if as_root
                @origin_descriptor = leaf_descriptor # 複数個あるとまずい
              else
                @possible_descriptors << leaf_descriptor
              end
            end
          end
          @applied_profile_urls << profile_url # TODO: 実はprofile_urlの保存よりも、適用済みdescriptorのfqidsを保存すべき
        end

        def items_for(descriptor_fqid, include_obj = true)
          descriptor = lookup_descriptor(descriptor_fqid)
          traverse(@data, descriptor, include_obj).compact
        end

        def first_item_for(descriptor_fqid, include_obj = true)
          items_for(descriptor_fqid, include_obj).first
        end
        alias item_for first_item_for

        def links_for(descriptor_fqid)
          # semanticとlinkを分ける必要あるかもしれないけど、呼ぶまでどちらかわからないのだからやっぱり統合すべきかも
          descriptor = lookup_descriptor(descriptor_fqid)
          items = traverse(@data, descriptor, false).compact
          items.map{|item| item.respond_to?(:descriptor) ? LinkedPoint.new(item, item.descriptor) : item }
        end

        def first_link_for(descriptor_fqid)
          links_for(descriptor_fqid).first
        end
        alias link_for first_link_for

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
            fqids = traversing_fqids(descriptor)

            case node
            when Array
              node.map do |child|
                traverse(child, descriptor, include_obj)
              end.flatten(1).compact
            when Hash
              traverse_values = node.slice(*fqids).map do |fqid, value|
                if include_obj
                  wrap(value, lookup_descriptor(fqid))
                elsif !(value.is_a?(Array) || value.is_a?(Hash))
                  # value
                  wrap(value, lookup_descriptor(fqid))
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

          def traversing_fqids(descriptor)
            fqids = descriptor.self_and_descendant_fqids
            local_ids = fqids.map{|fqid| fqid.match(/^#{@url}#/).try(:post_match) }.compact
            # 構造を考慮して候補から除く部分。ここがないと子要素全部取る
            possible_fqids = possible_descriptors.map(&:self_and_ancestor_fqids).flatten(1)
            fqids &= possible_fqids
            fqids.concat(local_ids)
          end

          def wrap(node, descriptor)
            case node
            when Array
              node.map{|n| wrap(n, descriptor) } # TODO: 再帰じゃなくて1段階だけwrapすればいいはずなんだが
            when Hash
              self.class.new(node, @url, descriptor)
            else
              node.extend(ValueWithDescriptor) # TODO: improve
              node.descriptor = descriptor
              node
            end
          end

          def leaf_fqid?(fqid)
            !fqid.include?('#') # TODO: alias名のときの処理
          end

          def complete_fqid(fqid)
            if leaf_fqid?(fqid)
              "#{url}##{fqid}"
            elsif fqid.start_with?('#')
              "#{url}#{fqid}"
            else
              fqid
            end
          end

          def lookup_descriptor(fqid)
            if leaf_fqid?(fqid)
              DescriptorStore.lookup_leaf(complete_fqid(fqid))
            else
              DescriptorStore.lookup(complete_fqid(fqid)) # TODO: complete_fqid はデフォルトでIANAを補完
            end
          end

          # 相対パス解決、ALPSの提供するURLに読み替える
          def resolve_alps_url(url)
            absolute_url =
              if URI.parse(url).absolute?
                url
              else
                (URI.parse(@url) + url).to_s
              end
            absolute_url.sub(%r|^http://schema\.org/|, 'http://alps.io/schema.org/')
          end
      end
    end
  end
end
