require 'spec_helper'

describe Eloqua::Asset do
  
  subject do
    Class.new(Eloqua::Asset) do
      self.remote_object_type = Eloqua::API.remote_object_type('ContactGroup')
      def self.name
        'ContactGroup'
      end
    end
  end
  
  specify { subject.remote_object.should == :asset }
  
  let(:asset) do
    Class.new(subject) do
      self.remote_object_type = Eloqua::API.remote_object_type('ContactGroupName', 'ContactGroup', 0)
      map :name => :name
      map :description => :description
    end
  end
  
  let(:entity) do
    Class.new(Eloqua::Entity) do
      self.remote_object_type = Eloqua::API.remote_object_type('Contact')
    end    
  end
  
  it_behaves_like 'supports CURD remote operations', :asset
  
  context "during group member class operations" do
    
    let(:xml_body) do
      asset.entity_association_xml(1, entity, 1)
    end
    
    context "#self.add_group_member" do
                  
      before do        
        mock = soap_fixture(:add_group_member, :success);
        
        flexmock(Eloqua::API).\
          should_receive(:send_remote_request).\
          with(:service, :add_group_member, xml_body).\
          returns(mock).once
        
        @result = asset.add_group_member(1, entity, 1)
      end
      
      it 'should return true' do
        @result.should be_true
      end

    end

    context "#self.remove_group_member" do
      
      before do
        mock = soap_fixture(:remove_group_member, :success);
        
        flexmock(Eloqua::API).\
          should_receive(:send_remote_request).\
          with(:service, :remove_group_member, xml_body).\
          returns(mock).once
        
        @result = asset.remove_group_member(1, entity, 1)
      end
      
      it 'should return true' do
        @result.should be_true
      end
      
    end    
    
  end
  

  
  context "#self.entity_association_xml" do
    
    let(:expected_xml) do
      xml_query = xml! do |xml|
        xml.template!(:object, :entity, entity.remote_object_type, 1)
        xml.template!(:object, :asset, asset.remote_object_type, 1)
      end
    end
    
    
    context 'when entity given is a class' do
      it 'should return expected xml' do
        output = asset.entity_association_xml(1, entity, 1)
        output.should == expected_xml
      end      
    end
    
    context 'when entity given is a hash' do
      it 'should return expected xml' do
        output = asset.entity_association_xml(1, entity.remote_object_type, 1)
        output.should == expected_xml
      end      
    end
    
  end
  
  # context "creating contact group" do
  #   
  #   
  #   it 'should create james contact group' do
  #     object = asset.new(
  #       :name => 'James created this contact group (again) !', :description => 'through the api =)'
  #     )
  #     object.save
  #   end
  #   
  # end
  
  # context 'find asset' do
  #   
  #   it 'should retreive asset' do
  #     object = asset.find(123)
  #     object.name = '(Test) Property #5760'
  #     pp object.save
  #   end
  #   
  # end  
      
  # context "when adding entity to contact group" do
  #   
  #   let(:james_id) { 130485 }
  #   
  #   it 'should list assets for james' do
  #     xml_query = xml! do |xml|
  #       xml.entity do
  #         xml.EntityType do
  #           xml.template!(:object_type, subject.api.remote_object_type('Contact'))
  #         end
  #         xml.Id(james_id)
  #       end
  #     end
  #     #pp subject.request(:list_group_membership, xml_query)
  #   end
  #   
  #   it 'should be added' do
  #     
  #     xml_query = xml! do |xml|
  #       xml.entity do
  #         xml.EntityType do
  #           xml.template!(:object_type, subject.api.remote_object_type('Contact'))
  #         end
  #         xml.Id(james_id)
  #       end
  #       xml.asset do
  #         xml.AssetType do
  #           xml.template!(:object_type, asset.remote_object_type)
  #         end
  #         xml.Id(123)
  #       end        
  #     end
  #     
  #     #pp subject.request(:add_group_member, xml_query)
  #     
  #   end
  #   
  #   it 'should be removed' do
  #     xml_query = xml! do |xml|
  #       xml.entity do
  #         xml.EntityType do
  #           xml.template!(:object_type, subject.api.remote_object_type('Contact'))
  #         end
  #         xml.Id(james_id)
  #       end
  #       xml.asset do
  #         xml.AssetType do
  #           xml.template!(:object_type, asset.remote_object_type)
  #         end
  #         xml.Id(123)
  #       end        
  #     end 
  #     #pp subject.request(:remove_group_member, xml_query)
  #   end
  #   
  # end
  
  # context 'delete asset' do
  #   
  #     it 'should retreive asset' do
  #       object = asset.find(123)
  #       object.name = '(Test) Property #5760'
  #       
  #       xml_query = asset.api.builder do |xml|
  #         xml.object_type_lower!(asset.remote_object) do
  #           xml.template!(:object_type, asset.remote_object_type)
  #         end
  #         xml.ids do
  #           xml.template!(:int_array, [123, 124, 125])
  #         end
  #       end
  #       
  #       object.request(:delete_asset, xml_query)
  #       
  #     end
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