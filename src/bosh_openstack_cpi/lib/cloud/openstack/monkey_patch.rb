#require 'fog'

module Fog
  module Image
    class OpenStack
      def OpenStack.new(args = {})
        @openstack_auth_uri = URI.parse(args[:openstack_auth_url]) if args[:openstack_auth_url]
        if self.inspect == 'Fog::Image::OpenStack'
          service = Fog::Image::OpenStack::V1.new(args)
        else
          service = Fog::Service.new(args)
        end
        service
      end
    end
  end
end

module ImageV1Extension
  def request(params)
    tmp_path = @path
    begin
      if params[:path].index("images/detail") == 0 && params[:method] == "GET"
        @path = "/v1"
      end

      super(params)
    ensure
      @path = tmp_path
    end
  end
end

module ComputeExtension
  def request(params)
    tmp_path = @path
    begin
      if params[:path].index("os-volumes") == 0 &&  params[:path].index("os-volumes_boot") != 0
#        @path = "/v1.1"
        @path = @path.sub(/v2/, "v1.1")
      end

      super(params)
    ensure
      @path = tmp_path
    end
  end
end

module MetadataExtension
  def get_metadata(collection_name, parent_id, key)
    metas = request(
      :expects  => [200, 203],
      :method   => 'GET',
      :path     => "#{collection_name}/#{parent_id}"
    ).body["server"]['metadata']

    if metas[key.to_s].nil?
      raise Fog::Compute::OpenStack::NotFound
    end

    body = Class.new do |clazz|
      def clazz.setMeta(_meta)
        @meta = _meta
      end
      def clazz.body

      {
        'meta' => @meta
      }
      end
    end

    body.setMeta({ key => metas[key.to_s] })

    body
  end
end

Fog::Image::OpenStack.send(:prepend, Fog)
Fog::Image::OpenStack::V1::Real.send(:prepend, ImageV1Extension)
Fog::Compute::OpenStack::Real.send(:prepend, ComputeExtension)
Fog::Compute::OpenStack::Real.send(:prepend, MetadataExtension)
