require 'spec_helper'

describe Eloqua::Entity do
  
  subject do
    Class.new(Eloqua::Entity) do
      self.remote_type = Eloqua::Api.remote_type('Contact')
      def self.name
        'ContactEntity'
      end
    end
  end

  let(:asset) do
    Class.new(Eloqua::Asset) do
      self.remote_type = api.remote_type('0', 'ContactGroup', '0')
    end
  end
  
  let(:object) do
    subject.new({:id => 1}, :remote)
  end
  
  it_behaves_like 'class level delegation of remote operations for', :entity

  context "membership methods" do

    context "#add_membership" do
      it 'should call remove_member on given asset' do
        flexmock(asset).should_receive(:add_member).with(object).once
        object.add_membership(asset)
      end
    end

    context "#remove_membership" do
      it 'should call remove_member on given asset' do
        flexmock(asset).should_receive(:remove_member).with(object).once
        object.remove_membership(asset)
      end
    end


  end

  context "#list_memberships" do
    
    it 'should delegate call to class level with current id' do
      flexmock(subject).should_receive(:list_memberships).with(1).once
      object.list_memberships
    end
    
  end

  context "#self.list_memberships" do
    it 'should delegate call to api' do
      flexmock(subject.api).should_receive(:list_memberships).with(subject.remote_type, 1).once
      subject.list_memberships(1)
    end
  end

  context "#self.remote_group" do
    specify { subject.remote_group.should == :entity }
  end
  
  
  context '#self.where' do
    let(:expected_query) { "C_EmailAddress='james@lightsofapollo.com'" }
    let(:klass) do
      Class.new(subject) do
        map :C_EmailAddress => :email
      end
    end

		context "when given no arguments" do
			it "should return an Eloqua::Query object" do
				query = subject.where
				query.should be_an(Eloqua::Query)
				query.remote_object.should == subject
			end
		end
    
    context "when successfuly finding single result with all fields" do
    
      let(:input) { {:email => 'james@lightsofapollo.com'} }
      let(:xml_body) do
        api = subject.api
        xml! do |xml|
          xml.eloquaType do
            xml.template!(:object_type, api.remote_type('Contact'))
          end
          xml.searchQuery(expected_query)
          xml.pageNumber(1)
          xml.pageSize(200)
        end
      end
      
      before do
        mock_eloqua_request(:query, :contact_email_one).\
            with(:service, :query, xml_body)
        
        @results = klass.where(input)
      end
      
      it 'should return an array' do
        @results.class.should == Array
      end
      
      it 'should return an array of objects' do
        @results.first.class.should == klass
      end
      
      it 'should have attributes acording to XML file (query/contact_email_one.xml)' do
        record = @results.first
        expected = {
          :id => '1',
          :email => 'james@lightsofapollo.com',
          :first_name => 'James'
        }
        record.attributes.length.should == 3
        expected.each do |attr, value|
          record.attributes[attr].should == value
        end
      end
      
    end

    context "when successfuly finding results with limited number of fields" do
      let(:input) { [{:email => 'james@lightsofapollo.com'}, [:email]] }
      let(:xml_body) do
        api = subject.api
        xml! do |xml|
          xml.eloquaType do
            xml.template!(:object_type, api.remote_type('Contact'))
          end
          xml.searchQuery(expected_query)
          xml.fieldNames do
            xml.template!(:array, ['C_EmailAddress'])
          end
          xml.pageNumber(1)
          xml.pageSize(200)
        end
      end
      
      before do
        mock_eloqua_request(:query, :contact_email_one).\
          with(:service, :query, xml_body)

        @results = klass.where(*input)
      end
      
      # HINT- This is actually asserted above in the mock_eloqua_request
      it "should request that the results only return the C_EmailAddress field" do
        @results.should be_true
      end

    end
    
    context "when rows are not found" do
      let(:input) { {:email => 'james@lightsofapollo.com'} }
      let(:xml_body) do
        api = subject.api
        
        xml! do |xml|
          xml.eloquaType do
            xml.template!(:object_type, api.remote_type('Contact'))
          end
          xml.searchQuery("C_EmailAddress='james@lightsofapollo.com'")
          xml.pageNumber(1)
          xml.pageSize(200)
        end
      end
      
      before do
        mock_eloqua_request(:query, :contact_missing).\
            with(:service, :query, xml_body)
        
        @results = klass.where(input)
      end
      
      specify { @results.should be_false }
      
    end
    
  end
  
  
end
