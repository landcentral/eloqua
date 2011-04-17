require 'spec_helper'
require 'eloqua/api/service'

shared_examples_for "entity association with response" do |type, name|

  let(:xml_body) do
    subject.entity_association_xml(asset_type, 1, entity_type, 1)
  end

  before do
    mock_eloqua_request(type, name).\
      with(:service, type, xml_body).once

    @result = subject.entity_asset_operation(type, asset_type, 1, entity_type, 1)
  end

  specify { @result.should be_true }

end

shared_examples_for "entity association operation" do |method|

  before do
    flexmock(subject).should_receive(:entity_asset_operation).with(method, asset_type, 1, entity_type, 1).once.returns(true)
  end

  it 'should use entity asset operation to make request' do
    subject.send(method, asset_type, 1, entity_type, 1)
  end

end

shared_examples_for "operations for entity and asset" do |group, type|

  let(:group_name) { group }

  let(:dynamic_key) { ("dynamic_#{group}".to_sym) }

  let(:field_key) { "#{group}_fields".to_sym }

  context "#self.group_methods" do
    specify { subject.group_methods.class.should == Array }
  end

  context "#self.group_type_methods" do
    specify { subject.group_type_methods.class.should == Array }
  end

  context "#self.type_methods" do
    specify { subject.type_methods.class.should == Array }
  end

  context '#self.create_object' do

    let(:result_key) { subject.key_with_object(group, :create_result) }
    let(:input) { [group, type, {:C_EmailAddress => 'create'}] }
    let(:create_result) do
      {
          result_key => {
              ("#{group}_type").to_sym => type,
              :errors => nil,
              :id => 1
          }
      }
    end

    context 'when successfuly creating one record' do

      let(:xml_body) do
        xml! do |xml|
          xml.object_collection!(group) do
            xml.dynamic_object!(group) do
              xml.template!(:dynamic, group, type, nil, {
                  :C_EmailAddress => 'create',
              })
            end
          end
        end
      end

      before do
        mock_api_request(remote_method(:create), xml_body, create_result)
        @results = subject.create_object(*input)
      end


      it 'should return {:id => 1}' do
        @results[:id].should == 1
      end

    end

    context "when the record is duplicate" do

      let(:create_result) do
        {
            result_key => {
                ("#{group}_type").to_sym => type,
                :errors => {
                    :error => {
                        :error_code => 'DuplicateValue',
                        :message => 'You are attempting to create a duplicate entity.'
                    }
                }
            }
        }
      end

      before do
        mock_api_request(create_result)
      end

      it 'should raise duplicate error exception' do
        lambda { subject.create_object(*input) }.should raise_exception(Eloqua::DuplicateRecordError)
      end

    end

  end

  context "#self.update_object" do

    let(:result_key) { subject.key_with_object(group, :update_result) }

    let(:update_result) do
      {
          result_key => {
              ("#{group}_type").to_sym => type,
              :errors => nil,
              :id => 1,
              :success => true
          }
      }
    end

    context "when successfully updating one record" do
      let(:input) { [group, type, 1, {:C_EmailAddress => 'new'}] }
      let(:xml_body) do
        xml! do |xml|
          xml.object_collection!(group) do
            xml.dynamic_object!(group) do
              xml.template!(:dynamic, group, type, '1', {
                  :C_EmailAddress => 'new',
              })
            end
          end
        end
      end

      before do
        mock_api_request(remote_method(:update), xml_body, update_result)
        @results = subject.update_object(*input)
      end

      it 'should return true' do
        @results.should be_true
      end

    end

  end

  context "#self.delete_object" do

    context "when given single int" do
      let(:result_key) { subject.key_with_object(group, :delete_result) }

      let(:delete_result) do
        {
            result_key => {
                ("#{group}_type").to_sym => type,
                :errors => nil,
                :id => 1,
                :success => true
            }
        }
      end
      let(:input) { 1 }
      let(:xml_body) do
        xml! do |xml|
          xml.object_type_lower!(group) do
            xml.template!(:object_type, type)
          end
          xml.ids do
            xml.template!(:int_array, [input])
          end
        end
      end

      before do
        mock_api_request(remote_method(:delete), xml_body, delete_result)
        @result = subject.delete_object(group, type, 1)
      end

      it 'should return an array of deleted ids' do
        @result.should == [1]
      end

    end
  end

  context "#self.find_object" do

    let(:find_result) do
      {
          dynamic_key => {
            :field_value_collection => {
                field_key => [{
                  :internal_name => 'C_EmailAddress',
                  :value => email
                }]
            },
            :id => '1'
          }
      }
    end

    context "successful find_object with all fields" do
      let(:xml_body) do
        xml! do |xml|
          xml.object_type_lower!(group) do
            xml.template!(:object_type, type)
          end
          xml.ids do
            xml.template!(:int_array, [1])
          end
        end
      end

      before do
        mock_api_request(remote_method(:retrieve), xml_body, find_result)
        @result = subject.find_object(group, type, 1)
      end

      it 'should return a hash with fields from retrieve' do
        @result.class.should == Hash
      end

      it 'should return hash with expected fields' do
        expected = {
            :C_EmailAddress => email,
            :id => 1
        }
        expected.each do |key, value|
          @result[key].should == value
        end

      end
    end
    
    context 'find_object without a result' do

      before do
        mock = mock_api_request(dynamic_key => nil)
        @result = subject.find_object(group, type, 5)
      end

      it 'should return false' do
        @result.should be_false
      end

    end

  end

end

describe Eloqua::Api::Service do
  
  subject { Eloqua::Api::Service }

  let(:email) { 'test@email.com' }

  let(:group) { :asset }

  let(:type) do
    subject.remote_object_type('Contact')
  end

  let(:asset_type) do
    subject.remote_object_type('ContactGroupName', 'ContactGroup', 0)
  end

  let(:entity_type) do
    subject.remote_object_type('Contact')
  end

  context "#self.entity_association_xml" do

    let(:expected_xml) do
      xml_query = xml! do |xml|
        xml.template!(:object, :entity, entity_type, 1)
        xml.template!(:object, :asset, asset_type, 1)
      end
    end


    context 'when entity given is a class' do
      it 'should return expected xml' do
        output = subject.entity_association_xml(asset_type, 1, entity_type, 1)
        output.should == expected_xml
      end
    end

    context 'when entity given is a hash' do
      it 'should return expected xml' do
        output = subject.entity_association_xml(asset_type, 1, entity_type, 1)
        output.should == expected_xml
      end
    end

  end

  context "#self.key_with_object" do

    it 'should return given when obj type is entity' do
      subject.key_with_object(:entity, :create_result).should == :create_result
    end

    it 'should inject asset in the middle of given method' do
      subject.key_with_object(:asset, :create_result).should == :create_asset_result
    end

  end

  context "#self.object_method" do
    it 'should return given name when obj type is entity' do
      subject.object_method(:entity, :create).should == :create
    end

    it 'should append obj type when type is other then entity' do
      subject.object_method(:asset, :create).should == :create_asset
    end
  end

  context "#self.request" do
    it 'should make requests with the :service client' do
      flexmock(Eloqua::Api).should_receive(:request).with(:service, :method, {})
      subject.request(:method, {})
    end
  end

  it_behaves_like 'operations for entity and asset', :asset, Eloqua::Api.remote_object_type('ContactGroupName', 'ContactGroup', 0)
  it_behaves_like 'operations for entity and asset', :entity, Eloqua::Api.remote_object_type('Contact')

  context "#self.list_memberships" do
    let(:xml_body) do
      xml! do |xml|
        xml.template!(:object, :entity, type, 1)
      end
    end

    before do
      mock_eloqua_request(:list_group_membership, :success).\
        with(:service, :list_group_membership, xml_body).once

      @result = subject.list_memberships(type, 1)
    end

    it "should provide array of contact groups" do
      @result
    end
  end

  context "during group member class operations" do

    let(:xml_body) do
      subject.entity_association_xml(asset_type, 1, entity_type, 1)
    end

    context "#self.entity_asset_operation" do

      context "when adding group member" do
        it_behaves_like 'entity association with response', :add_group_member, :success
      end

      context "when removing group member" do
        it_behaves_like 'entity association with response', :remove_group_member, :success
      end

    end

    context "#self.add_group_member" do
      it_behaves_like 'entity association operation', :add_group_member
    end

    context "#self.remove_group_member" do
      it_behaves_like 'entity association operation', :remove_group_member
    end

  end

  context "#self.list_types" do
    let(:remote_method) { "list_#{group}_types".to_sym }
    
    before do
      mock_eloqua_request(remote_method, :success).with(:service, remote_method, nil)
    end
        
    it 'should return results as an array' do
      result = subject.list_types(group)
      result.class.should == Array
    end
        
  end
    
  context "#self.describe" do
    let(:remote_method) { "describe_#{group}".to_sym }    
    
    let(:xml_body) do
      xml! do |xml|
        xml.object_type_lower!(group) do
          xml.template!(:object_type, type)
        end
      end
    end
    
    before do
      mock_eloqua_request(remote_method, :success).with(:service, remote_method, xml_body)
      @result = subject.describe(group, type)
    end
    
    it 'should have fields in the top level in result as an array' do
      @result.should have_key(:fields)
      @result[:fields].class.should == Array
    end
    
  end

  context "#self.describe_type" do

    shared_examples_for "will return collection of types" do
      it "should return an array" do
        @result.class.should == Array
      end

      it "should contain type hash in first element with :id, :name and :type keys" do
        first = @result.first
  
        first.should have_key(:id)
        first.should have_key(:name)
        first.should have_key(:type)
      end
      
    end

    context "when group is :asset" do
      let(:request_hash) do
        {:asset_type => 'Type'}
      end

      before do
        mock_eloqua_request(:describe_asset_type, :success).\
          with(:service, :describe_asset_type, request_hash).once
        @result = subject.describe_type(:asset, 'Type')
      end

      it_behaves_like 'will return collection of types'
    end

    context "when group is :entity" do
      let(:request_hash) do
        {:global_entity_type => 'Base'}
      end

      before do
        mock_eloqua_request(:describe_entity_type, :success).\
          with(:service, :describe_entity_type, request_hash).once

        @result = subject.describe_type(:entity, 'Base')
      end
      
      it_behaves_like 'will return collection of types'
    end

  end

  context "#self.handle_exception" do
    context 'duplicate error' do

      let(:response) do
        {:errors=>
             {:error=>
                  {:error_code=>"DuplicateValue",
                   :message=>"You are attempting to create a duplicate entity."}},
         :id=>"-1",
         :entity_type=>{:type=>"Base", :name=>"Contact", :id=>"0"}
        }
      end

      it 'should raise duplicate exception' do
        lambda { subject.handle_exception(response) }.should raise_exception(Eloqua::DuplicateRecordError)
      end

    end
  end

end
