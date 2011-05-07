require 'spec_helper'
require 'eloqua/query'


shared_examples_for "chainable query attribute that resets has_requested?" do |method, given|
  context "##{method}" do
    
    it "should act like a getter when given no value" do
      subject.send(method).should == subject.instance_variable_get("@#{method}".to_sym)
    end

    it "should act like a setter and return self when given a value" do
      subject.send(method, given).should === subject
      subject.send(method).should == given
    end

    context "when modifying #{method} after a request" do

      before do
        simple_request!
      end

      it "should reset has_requested to false" do
        subject.should have_requested
        subject.send(method, given)
        subject.should_not have_requested
      end

    end

  end
end

describe Eloqua::Query do
  subject { klass.new(entity) }
  let(:klass) { Eloqua::Query } 
  let(:expected_query) { "C_EmailAddress='*' AND Date>'2011-04-20'" }

  let(:entity) do
    Class.new(Eloqua::Entity) do
      self.remote_type = api.remote_type('Contact')
      map :C_EmailAddress => :email
    end
  end

  before do
    subject.request_delay = false
  end

  after { Timecop.return }

  def mock_query_hash(records, pages)
    entities = []
    records.to_i.times do |i|
      entities << {:field_value_collection=>
          {:entity_fields=>
            [{:value=>"james@lightsofapollo.com",
              :internal_name=>"C_EmailAddress"},
             {:value=>"James", :internal_name=>"C_FirstName"}]},
         :id=>"#{i + 1}",
         :entity_type=>{:type=>"Base", :name=>"Contact", :id=>"0"}
      }
    end
    {
      :total_pages=>"#{pages}",
      :total_records=>"#{records * pages}",
      :entities=>{ :dynamic_entity => entities },
      :i=>"http://www.w3.org/2001/XMLSchema-instance"
    }
  end

  def conditions!(query = nil)
    query = (query.nil?)? subject : query
    query.\
      on(:email, '=', '*').\
      on('Date', '>', '2011-04-20')
  end

  def limit!(query = nil, page = 1)
    query = (query.nil?)? subject : query
    query.page(page).limit(200)
  end

  def expect_simple_request(page = 1)
    xml_body = xml! do |xml|
      api = subject.remote_object.api
      xml.eloquaType do
        xml.template!(:object_type, api.remote_type('Contact'))
      end
      xml.searchQuery(expected_query)
      xml.pageNumber(page)
      xml.pageSize(200)
    end
    mock_eloqua_request(:query, :contact_email_one).\
      with(:service, :query, xml_body).globally.ordered.once
  end

  def round_1(number)
    sprintf('%.1f', number).to_f
  end

  def expect_request_pages(records, pages, current_page = nil, limit = 200)
    remote_results = mock_query_hash(records, pages)
    mock = mock_api_request(remote_results)
    if(current_page)
      xml_body = xml! do |xml|
        api = subject.remote_object.api
        xml.eloquaType do
          xml.template!(:object_type, api.remote_type('Contact'))
        end
        xml.searchQuery(expected_query)
        xml.pageNumber(current_page)
        xml.pageSize(limit)
      end
      mock.with(:query, xml_body)
    end
    mock
  end

  def simple_request!(page = 1)
    expect_simple_request(page)
    subject.clear_conditions!
    conditions!
    limit!(nil, page)
    subject.request!
  end


  context "#test.mock_query_hash" do
    it "should have proper number of pages" do
      mock = mock_query_hash(20, 20)
      mock[:total_pages].should == "20"
      mock[:total_records].should == (20 * 20).to_s
      mock[:entities][:dynamic_entity].length.should == 20
    end
  end


  context "#api" do
    it "should delegate #api to remote object" do
      flexmock(subject.remote_object).should_receive(:api).once
      subject.api
    end
  end

  context "#new" do
    
    it 'should raise ArgumentError when given anything but an Eloqua::RemoteObject' do
      lambda { klass.new({}) }.should raise_exception(ArgumentError, /must provide an Eloqua::RemoteObject /)
    end

    context "when initializing with Eloqua::RemoteObject" do
      it "should have saved remote subject to #remote_object" do
        subject.remote_object.should == entity
      end

      it "should preset the #page to 1" do
        subject.page.should == 1
      end

      it "should preset #limit to 200" do
        subject.limit.should == 200
      end

      it "should have an empty collection" do
        subject.collection.should be_empty
      end

      it "should have no conditions" do
        subject.conditions.should be_empty
      end

      it "should #fields should be nil" do
        subject.fields.should be_nil
      end
      
      it "should not have requested yet" do
        subject.should_not have_requested
      end

    end

  end

  it_behaves_like "chainable query attribute that resets has_requested?", :page, 5
  it_behaves_like "chainable query attribute that resets has_requested?", :limit, 5
  it_behaves_like "chainable query attribute that resets has_requested?", :fields, [:email, 'Date']

  context "#on" do

    context "adding a single condition" do
      before do
        @result = subject.on(:email, '=', '*')
      end

      it "should return self" do
        @result.should === subject
      end

      it "should have added condition" do
        subject.conditions.length.should == 1
      end

      it "should have added condition field, type and value" do
        subject.conditions.first.should == {
          :field => :email,
          :type => '=',
          :value => '*'
        }
      end

    end

    context "adding additional condition after request" do
      it "should have not made request" do
        subject.should_not have_requested
      end

      context "after request" do
        
        before do
          simple_request!
        end

        it "should have requested" do
          subject.should have_requested
        end

        it "should reset have requested when adding new condition" do
          subject.on(:email, '=', 'ouch')
          subject.should_not have_requested
        end

      end

    end

  end

  context "#clear_conditions!" do
    it "should clear conditions added by on" do
      subject.on(:email, '=', '1')
      subject.conditions.length.should == 1
      subject.clear_conditions!
      subject.conditions.length.should == 0
    end

    it "should reset #has_requested?" do
      simple_request!
      subject.should have_requested
      subject.clear_conditions!
      subject.should_not have_requested
    end

  end

  

  context "#build_query" do
    let(:entity) do
      Class.new(Eloqua::Entity) do
        map :C_EmailAddress => :email
        remote_type = api.remote_type('Contact')
      end
    end

    before do
      query = klass.new(entity)
      conditions!(query)
      @result = query.send(:build_query)
    end

    specify { @result.should == expected_query }
  end

  context "#request" do
    context "when requesting without limiting the fields and remote returns one result" do
      before do
        @result = simple_request!
      end

      it "should return an array of objects" do
        @result.should be_an(Array)
        @result.first.should be_an(Eloqua::Entity)
      end

      it "should now mark query as #has_requested?" do
        subject.should have_requested
      end

      it "should have added results to collection" do
        subject.collection.length.should == 1
      end

      it "should have set total pages to 1" do
        subject.total_pages.should == 1
      end

      it 'should have attributes acording to XML file (query/contact_email_one.xml)' do
        record = subject.collection.first
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
          flexmock(subject.api).should_receive(:send_remote_request).never
          subject.should have_requested
          subject.request!
        end
      end

    end

    context "when successfuly finding results with limited number of fields" do
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
        
        conditions!

        @result = subject.fields([:email]).request!
      end
      
      # HINT- This is actually asserted above in the mock_eloqua_request
      it "should request that the results only return the C_EmailAddress field" do
       subject.should have_requested
      end

    end

    context "when rows are not found" do
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
        mock_eloqua_request(:query, :contact_missing).\
            with(:service, :query, xml_body)

        conditions!
        subject.request!
      end
      
      it "should an empty collection" do
        subject.collection.should be_empty
      end
    
      it "should have requested" do
        subject.should have_requested
      end

      it "should have total pages as 0" do
        subject.total_pages.should == 0
      end

    end

    # Eloqua has a request limit of 1 per second on queries.
    # The goal of this spec is to specify that no requests run
    # for at least a second after the first request.
    context "when making a request within the time of the request delay" do
      
      it "should save the initial request time to query_started" do
        Timecop.freeze(Time.now) do
          simple_request!
          subject.send(:query_started).should == Time.now
        end
      end

      context "with #request_delay of 1" do
        before { subject.request_delay = 1 }
        let(:now) { Time.now }

        it "should call sleep when requesting again within the delay" do
          Timecop.freeze(now) do
            simple_request! # Setup initial request

            flexmock(subject).should_receive(:sleep).with(FlexMock.on {|arg| round_1(arg) == 0.9 }).once
            Timecop.travel(now + 0.1)
            simple_request!(2)
          end
        end

        it "should not call sleep when request has been made after delay" do
          Timecop.freeze(now) do
            simple_request!
            flexmock(subject).should_receive(:sleep).never
            Timecop.travel(now + 1.1)
            simple_request!(2)
          end
        end
      

      end
    end

  end

  context "#wait_for_request_delay" do

    it "should return false when request_delay is false" do
      subject.request_delay = false
      simple_request! # set query start time

      subject.wait_for_request_delay.should == false
    end

    it "should retun false when query_started is false" do
      subject.request_delay = 1
      subject.wait_for_request_delay.should == false
    end

    it "should the amount of time to wait as a fraction when a delay is required" do
      subject.request_delay = 1
      now = Time.now
      Timecop.freeze(now) do
        simple_request!
        Timecop.travel(now + 0.1)
        delay = round_1(subject.wait_for_request_delay)
        delay.should == 0.9
      end
    end

  end

  context "#all" do

    context "when request has not yet been made" do

      before do
        expect_simple_request
        conditions!
        limit!

        @result = subject.all
      end

      it "should have made request" do
        subject.should have_requested
      end

      it "should return an array of objects" do
        @result.should be_an(Array)
        @result.first.should be_an(Eloqua::Entity)
      end
        
    end

  end

  context "#each" do
    before do
      expect_request_pages(20, 1)
      conditions!
      limit!
    end

    it "should iterator through each result and mark query as requested" do
      subject.should_not have_requested
      ids = []
      subject.each do |record|
        record.should be_an(Eloqua::Entity)
        ids << record.id
      end
      ids.length.should == 20
      ids.should == ('1'..'20').to_a
      subject.should have_requested
    end

  end


  context "#each_page" do
   
    let(:total) { 10 }
    let(:pages) { 5 }
    let(:limit) { 2 }
    let(:expected_range) { (1..5).to_a }
    let(:expected_ids) { (['1', '2'] * 5) }

    context "when iterating through 5 pages of results" do

      before do

        # - Clarity over brief
        expect_request_pages(limit, pages, 1, limit)
        expect_request_pages(limit, pages, 2, limit)
        expect_request_pages(limit, pages, 3, limit)
        expect_request_pages(limit, pages, 4, limit)
        expect_request_pages(limit, pages, 5, limit)

        @ids = []
        @pages = []

        conditions!
        subject.limit(limit)

        last_page = 0
        subject.each_page do |record|
          @ids << record.id
      
          if(last_page != subject.page)
            @pages << subject.page
            last_page = subject.page
          end
        end
      end

      it "should have iterated through 5 pages" do
        @pages.should == expected_range
      end

      it "should have iterated through all records in each page" do
        @ids.length.should == total
        @ids.should == expected_ids
      end

    end

    context "when iterating through 5 out of 10 pages" do
      
      let(:pages) { 10 }

      before do
        # - Clarity over brief
        expect_request_pages(limit, pages, 1, limit)
        expect_request_pages(limit, pages, 2, limit)
        expect_request_pages(limit, pages, 3, limit)
        expect_request_pages(limit, pages, 4, limit)
        expect_request_pages(limit, pages, 5, limit)

        @ids = []
        @pages = []

        conditions!
        subject.limit(limit)

        last_page = 0
        # Max of 5 pages
        subject.each_page(5) do |record|
          @ids << record.id
      
          if(last_page != subject.page)
            @pages << subject.page
            last_page = subject.page
          end
        end
      end

      it "should have iterated through 5 pages" do
        @pages.should == expected_range
      end

      it "should have iterated through all records in each page" do
        @ids.length.should == total
        @ids.should == expected_ids
      end

    end  

  end

end
