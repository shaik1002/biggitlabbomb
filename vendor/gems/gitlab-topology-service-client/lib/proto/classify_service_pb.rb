# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: proto/classify_service.proto

require 'google/protobuf'

require 'proto/cell_info_pb'
require 'google/api/annotations_pb'
Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("proto/classify_service.proto", :syntax => :proto3) do
    add_message "gitlab.cells.topology_service.ClassifyRequest" do
      optional :type, :enum, 2, "gitlab.cells.topology_service.ClassifyType"
      optional :value, :string, 3
    end
    add_message "gitlab.cells.topology_service.ProxyInfo" do
      optional :address, :string, 1
    end
    add_message "gitlab.cells.topology_service.ClassifyResponse" do
      optional :action, :enum, 1, "gitlab.cells.topology_service.ClassifyAction"
      optional :proxy, :message, 2, "gitlab.cells.topology_service.ProxyInfo"
    end
    add_enum "gitlab.cells.topology_service.ClassifyType" do
      value :UnknownType, 0
      value :FirstCell, 1
      value :SessionPrefix, 2
    end
    add_enum "gitlab.cells.topology_service.ClassifyAction" do
      value :UnknownAction, 0
      value :Proxy, 1
    end
  end
end

module Gitlab
  module Cells
    module TopologyService
      ClassifyRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("gitlab.cells.topology_service.ClassifyRequest").msgclass
      ProxyInfo = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("gitlab.cells.topology_service.ProxyInfo").msgclass
      ClassifyResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("gitlab.cells.topology_service.ClassifyResponse").msgclass
      ClassifyType = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("gitlab.cells.topology_service.ClassifyType").enummodule
      ClassifyAction = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("gitlab.cells.topology_service.ClassifyAction").enummodule
    end
  end
end
