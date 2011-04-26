require 'spec_helper'
require 'eloqua/query'


shared_examples_for "chainable query attribute that resets has_requested?" do |method, given|
  context "##{method}" do
    
    it "should act like a getter when given no value" do
      object.send(method).should == object.instance_variable_get("@#{method}".to_sym)
    end

    it "should act like a setter and return self when given a value" do
      object.send(method, given).should === object
      object.send(method).should == given
    end

    context "when modifying #{method} after a request" do

      before do
        make_simple_request!
      end

      it "should reset has_requested to false" do
        object.should have_requested
        object.send(method, given)
        object.should_not have_requested
      end

    end

  end
end

describe Eloqua::Query do
  subject { Eloqua::Query } 


  let(:entity) do
    Class.new(Eloqua::Entity) do
      self.remote_type = api.remote_type('Contact')
      map :C_EmailAddress => :email
    end
  end

  let(:object) { subject.new(entity) }

  def make_simple_request!
    expected_query = "C_EmailAddress='*' AND Date>'2011-04-20'"
    xml_body = xml! do |xml|
      api = object.remote_object.api
      xml.eloquaType do
        xml.template!(:object_type, api.remote_type('Contact'))
      end
      xml.searchQuery(expected_query)
      xml.pageNumber(2)
      xml.pageSize(100)
    end

    mock_eloqua_request(:query, :contact_email_one).\
      with(:service, :query, xml_body).once
    object.\
      condition(:email, '=', '*').\
      condition('Date', '>', '2011-04-20').\
      page(2).\
      limit(100).\
      request!
  end


  context "#api" do
    it "should delegate #api to remote object" do
      flexmock(object.remote_object).should_receive(:api).once
      object.api
    end
  end

  context "#new" do
    
    it 'should raise ArgumentError when given anything but an Eloqua::RemoteObject' do
      lambda { subject.new({}) }.should raise_exception(ArgumentError, /must provide an Eloqua::RemoteObject /)
    end

    context "when initializing with Eloqua::RemoteObject" do
      it "should have saved remote object to #remote_object" do
        object.remote_object.should == entity
      end

      it "should preset the #page to 1" do
        object.page.should == 1
      end

      it "should preset #limit to 200" do
        object.limit.should == 200
      end

      it "should have an empty collection" do
        object.collection.should be_empty
      end

      it "should have no conditions" do
        object.conditions.should be_empty
      end

      it "should #fields should be nil" do
        object.fields.should be_nil
      end
      
      it "should not have requested yet" do
        object.should_not have_requested
      end

    end
  end

  it_behaves_like "chainable query attribute that resets has_requested?", :page, 5
  it_behaves_like "chainable query attribute that resets has_requested?", :limit, 5
  it_behaves_like "chainable query attribute that resets has_requested?", :fields, [:email, 'Date']

  context "#condition" do

    context "adding a single condition" do
      before do
        @result = object.condition(:email, '=', '*')
      end

      it "should return self" do
        @result.should === object
      end

      it "should have added condition" do
        object.conditions.length.should == 1
      end

      it "should have added condition field, type and value" do
        object.conditions.first.should == {
          :field => :email,
          :type => '=',
          :value => '*'
        }
      end
    end

  end

  context "#build_query" do
    let(:entity) do
      Class.new(Eloqua::Entity) do
        map :C_EmailAddress => :email
        remote_type = api.remote_type('Contact')
      end
    end

    let(:expected) do
      [
        "C_EmailAddress='*'",
        "Date>'2011-04-20'"
      ].join(' AND ')
    end

    before do
      query = subject.new(entity)
      query.\
        condition(:email, '=', '*').
        condition('Date', '>', '2011-04-20')
      @result = query.send(:build_query)
    end

    specify { @result.should == expected }
  end

  context "#request" do
    let(:expected_query) { 'C_EmailAddress=\'*\'' }
    
    context "when requesting without limiting the fields and remote returns one result" do
      let(:expected_query) { "C_EmailAddress='*' AND Date>'2011-04-20'" }
      before do
        @result = make_simple_request!
      end

      it "should return an array of objects" do
        @result.should be_an(Array)
        @result.first.should be_an(Eloqua::Entity)
      end

      it "should now mark query as #has_requested?" do
        object.should have_requested
      end

      it "should have added results to collection" do
        object.collection.length.should == 1
      end

      it "should have set total pages to 1" do
        object.total_pages.should == 1
      end

      it 'should have attributes acording to XML file (query/contact_email_one.xml)' do
        record = object.collection.first
        record.should be_an(Eloqua::Entity)
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

      context "when has_requested? is true" do
        it "should send a remote request again" do
          flexmock(object.api).should_receive(:send_remote_request).never
          object.should have_requested
          object.request!
        end
      end

    end

    context "when successfuly finding results with limited number of fields" do
      let(:xml_body) do
        api = object.api
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
        
        @result = object.\
          condition(:email, '=', '*').
          fields([:email]).\
          request!
      end
      
      # HINT- This is actually asserted above in the mock_eloqua_request
      it "should request that the results only return the C_EmailAddress field" do
       object.should have_requested
      end

    end

    context "when rows are not found" do
      let(:xml_body) do
        api = object.api
        
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
        mock_eloqua_request(:query, :contact_missing).\
            with(:service, :query, xml_body)
      object.\
        condition(:email, '=', '*').
        request!        
      end
      
      it "should an empty collection" do
        object.collection.should be_empty
      end
    
      it "should have requested" do
        object.should have_requested
      end

      it "should have total pages as 0" do
        object.total_pages.should == 0
      end

    end

  end

end
