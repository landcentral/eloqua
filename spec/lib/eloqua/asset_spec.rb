require 'spec_helper'

describe Eloqua::Asset do

  subject { Eloqua::Asset }
  
  specify { subject.remote_object.should == :asset }
  
  let(:asset) do
    asset = subject.api.remote_object_type('ZZ - Test Contacts', 'ContactGroup', 12)
  end
  

  let(:klass) do
    Class.new(subject) do
      self.remote_object_type = Eloqua::API.remote_object_type('ContactGroupName', 'ContactGroup', 0)
      map :name => :name
      map :description => :description
    end
  end
  
  #it_behaves_like 'supports CURD remote operations', :asset
  
  # context "creating contact group" do
  #   
  #   
  #   it 'should create james contact group' do
  #     object = klass.new(
  #       :name => 'James created this contact group (again) !', :description => 'through the api =)'
  #     )
  #     object.save
  #   end
  #   
  # end
  
  # context 'find asset' do
  #   
  #   it 'should retreive asset' do
  #     object = klass.find(123)
  #     object.name = '(Test) Property #5760'
  #     pp object.save
  #   end
  #   
  # end
  
  # it 'should list all assets' do
  #   pp subject.request(:list_asset_types)
  # end
  
  # it 'should describe asset type' do
  #   xml_query = subject.api.builder do |xml|
  #     xml.assetType('ContactGroup')
  #   end
  #   pp subject.request(:describe_asset_type, xml_query)
  # end
  
  # it 'should describe asset' do
  #   asset = subject.api.remote_object_type('ContactGroupName', 'ContactGroup', 1)
  #   xml_query = subject.api.builder do |xml|
  #     xml.assetType do
  #       xml.template!(:object_type, asset)
  #     end
  #   end
  #   
  #   request = subject.request(:describe_asset, xml_query)
  #   pp request
  # end
  
  # it 'should retrieve asset' do
  #   xml_query = subject.api.builder do |xml|
  #     xml.assetType do
  #       xml.template!(:object_type, asset)
  #       xml.ids do
  #         xml.template!(:int_array, [1])
  #       end
  #     end
  #   end
  #   request = subject.request(:retrieve_asset, xml_query)
  #   pp request
  # end

end