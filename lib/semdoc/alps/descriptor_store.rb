module Semdoc
  module Alps
    class DescriptorStore
      @@store = {}
      @@document = {}
      @@connection =
        Faraday.new do |faraday|
          faraday.response :xml,  :content_type => /\bxml$/
          faraday.response :json, :content_type => /\bjson$/
          faraday.response :logger
          faraday.use :instrumentation
          faraday.use :http_cache, store: Rails.cache, serializer: Marshal
          faraday.adapter Faraday.default_adapter
        end

      # Example:
      # ab = DescriptorStore.lookup('http://alps.io/schema.org/BlogPosting#articleBody')
      def self.lookup(fqid)
        namespace, fragment = fqid.split('#')
        parse(namespace) unless @@store[fqid] # TODO: わかりやすく
        puts "Not found: #{fqid}" unless @@store[fqid]
        @@store[fqid]
      end

      def self.lookup_all(namespace)
        # TODO: @@store[document_url][short_id] の形に格納しておけば楽
        parse(namespace)
        @@store.map do |fqid, descriptor|
          fqid.start_with?("#{namespace}#") ? descriptor : nil
        end.compact
      end

      def self.lookup_leaf(fqid)
        return @@store[fqid] if @@store[fqid]
        namespace, fragment = fqid.split('#')
        OrphanedLeafDescriptor.new(namespace: namespace, short_id: fragment)
      end

      def self.add(descriptor)
        if @@store[descriptor.fqid]
          puts "Already registered: #{descriptor.fqid}"
        else
          puts "Register: #{descriptor.fqid}"
          @@store[descriptor.fqid] = descriptor
        end
        descriptor
      end

      def self.add_leaf(descriptor) # 暫定コピペ
        if @@store[descriptor.fqid]
          puts "Already registered: #{descriptor.fqid}"
        else
          puts "Register leaf: #{descriptor.fqid}"
          @@store[descriptor.fqid] = descriptor
        end
        descriptor
      end

      def self.create_alias(new_dqid, original_dqid)
        puts "Alias: #{new_dqid} -> #{original_dqid}"
        @@store[new_dqid] = @@store[original_dqid]
      end

      # def self.define_profile(profile_url, document_url)
      #   if alps = parse(profile_url) # TODO: profile definitionのキャッシュ
      #     Array.wrap(alps['descriptor']).each do |data_descriptor|
      #       define_leaf_descriptor(data_descriptor, profile_url, document_url)
      #     end
      #   end
      # end

      def self.define_leaf_descriptor(parent_data, parent_namespace, document_url)
        parent_fqid =
          if parent_data['id']
            "#{parent_namespace}##{parent_data['id']}"
          else
            grandparent = lookup(parent_data['href'])
            "#{parent_namespace}##{grandparent.short_id}"
          end
        parent = lookup(parent_fqid)
        descriptor = Descriptor.new(namespace: document_url, parent: parent)
        # parent.subdescriptors.each do |parent_subdescriptor|
        #   descriptor.subdescriptors << add(Descriptor.new(namespace: document_url, parent: parent_subdescriptor)) # FIXME: subsubdescriptorがない
        # end
        if parent_data['descriptor']
          Array.wrap(parent_data['descriptor']).each do |data_subdescriptor|
            descriptor.subdescriptors << define_leaf_descriptor(data_subdescriptor, parent_namespace, document_url) # FIXME: idの重複
          end
        end
        add_leaf(descriptor)
      end

      def self.define_descriptor(data, namespace = '')
        parent = lookup(data['href']) if data['href']
        short_id = data['id']
        type = data['type']
        rt = data['rt']
        descriptor = Descriptor.new(namespace: namespace, short_id: short_id, type: type, rt: rt, parent: parent)
        # subdescriptorの自動継承は設計がまずいのでひとまず無効に
        # if parent
        #   parent.subdescriptors.each do |parent_subdescriptor|
        #     descriptor.subdescriptors << add(Descriptor.new(namespace: namespace, parent: parent_subdescriptor)) # FIXME: subsubdescriptorがない
        #   end
        # end
        if data['descriptor']
          Array.wrap(data['descriptor']).each do |data_subdescriptor|
            descriptor.subdescriptors << define_descriptor(data_subdescriptor, namespace) # FIXME: idの重複
          end
        end
        add(descriptor)
      end

      def self.parse(document_url)
        return @@document[document_url] if @@document[document_url]
        body = fetch_document(document_url)
        if alps = body['alps']
          descriptors = Array.wrap(alps['descriptor']).map do |data_descriptor|
            define_descriptor(data_descriptor, document_url)
          end
          if descriptors.length == 1
            create_alias(document_url, descriptors.first.fqid)
          end
          @@document[document_url] = alps
        end
      end

      def self.parse_file(filename_or_url)
        document_url =
          if filename_or_url.start_with?('file://')
            filename_or_url
          else
            fullpath = File.expand_path(filename_or_url, Rails.root) # TODO: Remove Rails.root
            "file://#{fullpath}"
          end
        parse(document_url)
      end

      def self.fetch_document(url, accept: nil)
        uri = URI.parse(url)
        case uri.scheme
        when 'file'
          filename = url.sub(%r|^file://|, '')
          doc = File.read(filename)
          begin
            JSON.parse(doc)
          rescue JSON::ParserError # TODO: improve
            MultiXml::Parse(doc)
          end
        when 'http', 'https'
          accept_header = {'Accept' => accept} if accept
          response = @@connection.get(url, nil, accept_header)
          response.body
        else
          raise "URL #{url} not supported"
        end
      end
    end
  end
end
