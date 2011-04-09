require 'spec_helper'

describe Eloqua::Entity do
  
  def create_xml(&block)
    subject.api.builder(&block)
  end
  
  subject do
    Class.new(Eloqua::Entity) do
      self.entity_type = 'Contact'
      def self.name
        'ContactEntity'
      end
    end
  end

  let(:entity) do
    subject.api.entity('Contact')
  end


  context "#initialize" do

    context "when :remote" do
      before do
        @class = Class.new(subject) do
          map :ContactID => :id
          map :C_EmailAddress => :email
          attr_checkbox :california, :arizona
        end
      end

      let(:input) do
        {
            :C_EmailAddress => 'email@address.com',
            :ContactID => '1',
            :normal_id => 'wow',
            :C_California => 'Yes',
            :C_Arizona => 'No'
        }
      end

      let(:expected) do
        {
            :email => 'email@address.com',
            :id => '1',
            :normal_id => 'wow',
            :california => true,
            :arizona => false
        }.with_indifferent_access
      end

      it 'should map objects for adding them to #attributes' do
        object = @class.new(input, :remote) # true is remote == true
        object.attributes.should == expected
      end
      

            
    end

    context "when creating object" do          

    end

  end
  
  context '#persisted?' do
    
    it 'should be false when created with new' do
      subject.new.should_not be_persisted
    end
    
    it 'should be true when initializing with id' do
      subject.new(:id => '1').should be_persisted
    end
    
    context 'when initialized with :remote' do
      it 'should be considered persisted' do
        subject.new({:C_EmailAddress => 'email'}, :remote).should be_persisted
      end
    end
  end
  
  context "#valid?" do
    let(:klass) do
      Class.new(subject) do
        map :C_EmailAddress => :email
        validates_presence_of :email
        
        def self.name
          'Contact'
        end
        
      end      
    end
    
    context 'when valid' do
      
      before do
        @object = klass.new(:email => 'wow')
      end
      
      it 'should be valid?' do
        @object.should be_valid
      end
      
      it 'should not have any errors' do
        @object.valid?
        @object.errors[:email].should be_empty
      end
      
    end
    
    context 'when invalid' do
      
      before do
        @object = klass.new()
        @results = @object.valid?
      end
      
      it 'should be invalid?' do
        @object.should be_invalid
      end
      
      it 'should have errors on :email' do
        @object.errors[:email].should_not be_empty
      end
      
    end
    
  end
  
  context "#read_attribute" do
    let(:object) { subject.new(:email => 'address') }
    specify { object.read_attribute(:email).should == 'address' }
  end
  
  context '#write_attribute' do
    let(:object) { subject.new(:email => 'address') }

    it 'should set attribute' do
      object.write_attribute(:email, 'test')
      object.attributes[:email].should == 'test'
    end
  end
  
  context "#is_attribute_method?" do
    
    let(:object) { subject.new(:email => 'address') }
    
    it 'should return true for writers' do
      object.is_attribute_method?(:email=).should == :write
    end
    
    it 'should return true for readers' do
      object.is_attribute_method?(:email).should == :read
    end
    
    it 'should not return true for missing attrs' do
      object.attributes.delete(:email)
      object.is_attribute_method?(:email).should be_false
    end
    
  end

  context "when calling attribute method without concrete definition" do
    
    let(:klass) do
      Class.new(subject) do
        map :C_EmailAddress => 'email'
      end
    end
    

    let(:object) do
      klass.new({:C_EmailAddress => 'james@lightsofapollo.com'}, :remote)
    end
    
    specify { object.respond_to?(:email) }
    specify { object.respond_to?(:email=) }
    
    it 'should allow us to access attributes via accessors (email)' do
      object.email.should == 'james@lightsofapollo.com'
    end
    
    it 'should allow us to alter email via email=' do
      object.email = 'newemail'
      object.email.should == 'newemail'
      object.attributes[:email].should == 'newemail'
    end
    
    context 'when initalizing empty object' do
      let(:object) { klass.new }
      
      it 'should respond to mapped attribute email' do
        object.respond_to?(:email).should be_true
      end
      
      it 'should allow us to set and read attribute' do
        object.email = 'email'
        object.email.should == 'email'
      end
      
    end

  end

  context "#map_attributes" do

    let(:input) do
      {
          :C_EmailAddress => 'email@address.com',
          :ContactID => '1',
          :normal_id => 'wow'
      }.with_indifferent_access
    end

    let(:expected) do
      {
          :email_address => 'email@address.com',
          :id => '1',
          :normal_id => 'wow'
      }.with_indifferent_access
    end

    let(:reverse) do
      {
        :email_address => 'C_EmailAddress',
        :id => 'ContactID',
        :normal_id => 'normal_id'
      }.with_indifferent_access
    end

    before do
      klass_object = Class.new(subject) do
        map :ContactID => 'id'
      end
      @klass = klass_object.new({}, :remote)
      @result = @klass.send(:map_attributes, input)
    end

    it 'should map attributes from CamelCase format to snake_case format' do
      @result.should == expected
    end

    it 'should store the original key names in attribute_keys_to_eloqua' do
      @klass.attribute_keys_to_eloqua.should == reverse
    end

    context "#reverse_map_attributes" do

      before do
        @reversed = @klass.send(:reverse_map_attributes, @result)
      end

      it 'should be able to reverse map_attributes back into input' do
        @reversed.should == input  
      end

    end

  end
  
  context "#update_attributes" do
    context "when successfuly updating attributes" do
      let(:input) do
        {:email => 'email', :name => 'first'}
      end

      let(:klass) do
        Class.new(subject) do
          map :C_EmailAddress => :email
          map :C_FirstName => :name
          map :ContactID => :id
        end
      end

      let(:object) { klass.new(:id => 1) }

      let(:expected) do
        {
          :C_EmailAddress => 'email',
          :C_FirstName => 'first'
        }.with_indifferent_access
      end

      before do
        flexmock(klass).should_receive(:update_entity).\
                           with(1, expected).and_return(true)

        @result = object.update_attributes(input)      
      end

      it 'should call update entity to make the api call' do
        @result.should be_true
      end

      specify { object.email.should == 'email' }
      specify { object.name.should == 'first' }      
    end
    
    context 'when using attr_accessable to limit mass assignment' do
      let(:input) do
        {:email => 'email', :name => 'first'}
      end

      let(:klass) do
        Class.new(subject) do
          map :C_EmailAddress => :email
          map :C_FirstName => :name
          map :ContactID => :id
          
          attr_accessible :email
          
        end
      end

      let(:object) { klass.new(:id => 1, :name => 'james') }

      let(:expected) do
        {
          :C_EmailAddress => 'email',
        }.with_indifferent_access
      end      
      
      before do
        flexmock(klass).should_receive(:update_entity).\
                           with(1, expected).and_return(true)

        @result = object.update_attributes(input)      
      end

      it 'should call update entity to make the api call' do
        @result.should be_true
      end

      specify { object.email.should == 'email' }
      specify { object.name.should == 'james' }
    end    
        
  end

  context "#self.attr_type_hash" do

    let(:expected) do
      {
        :type => :my_name,
        :import => :import_my_name,
        :export => :export_my_name
      }
    end

    it 'should return a hash with the expected output' do
      subject.attr_type_hash(:my_name).should == expected
    end

  end

  context '#export_boolean_checkbox' do
    let(:object) { subject.new }

    it 'should return Yes when given true' do
      object.send(:export_boolean_checkbox, :mock, true).should == 'Yes'
    end

    it 'should return No when given false' do
      object.send(:export_boolean_checkbox, :mock, false).should == 'No'
    end

  end

  context "#self.attr_boolean_checkbox" do

    let(:klass) do
      Class.new(subject) do
        attr_checkbox :california
      end
    end

    it 'should have registered "california" as :checkbox in attribute_types' do
      klass.attribute_types[:california].should == {
        :type => :boolean_checkbox,
        :import => :import_boolean_checkbox,
        :export => :export_boolean_checkbox
      }.with_indifferent_access
    end

    context "when creating object with checkbox as Yes" do
      let(:object) { klass.new(:california => 'Yes') }
      specify { object.attributes[:california].should == true }
    end

    context 'when creating object with checkbox as No' do
      let(:object) { klass.new(:california => 'No') }
      specify { object.attributes[:california].should == false }
    end

    context 'when creating object with checkbox as true' do
      let(:object) { klass.new(:california => true) }
      specify { object.attributes[:california].should == true }
    end

    context 'when creating object with checkbox as false' do
      let(:object) { klass.new(:california => false) }
      specify { object.attributes[:california].should == false }
    end        
  end

  context "#self.map" do

    before do
      @class = Class.new(Eloqua::Entity) do
        self.entity_type = 'Contact'
      end      
    end

    it 'should be able to use map on the class level to map attributes' do
      @class.map :id => 'C_Attribute'
      @class.attribute_map[:id].should == :C_Attribute
    end

    it 'should be able to override existing maps' do
      @class.map :id => 'not_me'
      @class.map :id => 'me'
      @class.attribute_map[:id].should == :me
    end
    
    context 'when reverse' do
      it 'should also add the reverse to attribute_map_reverse' do
        @class.map :Contact => 'name'
        @class.map :IDC => 'id', :Real => 'email'

        reverse = {
          :name => :Contact,
          :id => :IDC,
          :email => :Real
        }.with_indifferent_access
        @class.attribute_map_reverse.should == reverse
      end
    end

  end
  
  context '#self.primary_key' do
    it 'is "id" by default' do
      subject.primary_key.should == 'id'
    end
  end
  
  context '#self.eloqua_attribute' do
    
    before do
      @class = Class.new(subject) do
        map :C_EmailAddress => :email
      end
    end
    
    it 'should return eloqua name "C_EmailAddress"' do
      @class.eloqua_attribute(:email).should == 'C_EmailAddress'
    end

    
  end

  context "#self.map_attribute" do

    before do
      @class = Class.new(subject) do
        map :name => 'C_Name', :id => 'ContactID'
      end
    end

    it 'should return value in attribute_map when given a key exists' do
      @class.map_attribute(:name).should == :C_Name
    end

    it 'should return given value when key does not exist within attribute_map' do
      @class.map_attribute(:Cezar).should == 'Cezar'
    end

  end

  context "#self.attribute_map" do
    specify { subject.attribute_map.class == Hash }

    context "when inherited entity attribute map is cloned by not the same object" do
      before do
        @super = Class.new(subject)
        @super.attribute_map[:id] = 'ContactID'
        @child = Class.new(@super)
      end

      it 'should have all the same keys' do
        @child.attribute_map.keys.should == @super.attribute_map.keys 
      end

      it 'should have all the same values' do
        @child.attribute_map.values.should == @super.attribute_map.values
      end

      it 'should not be the same object as parent' do
        @child.attribute_map.object_id.should_not === @super.attribute_map.object_id
      end

    end
    
  end

  context "#self.api" do
    it 'should have api on the class level' do
      subject.api.should == Eloqua::API
    end
  end

  context "#self.client" do
    it 'should call client(:service) on api' do
      flexmock(subject.api).should_receive(:client).with(:service).once
      subject.client
    end
  end

  context "#self.request" do
    it 'should make requests with the :service client' do
      flexmock(subject.api).should_receive(:request).with(:service, :method, {})
      subject.request(:method, {})
    end
  end

  context "#self.find" do
    
    context "successful find with all fields" do
      let(:xml_body) do
        create_xml do |xml|
          xml.entityType do
            xml.template!(:entity, entity)
          end
          xml.ids do
            xml.template!(:int_array, [1])
          end
        end
      end

      before do
        mock = soap_fixture(:retrieve, :contact_single)
        flexmock(subject.api).should_receive(:send_remote_request).with(:service, :retrieve, xml_body).and_return(mock)
        @result = subject.find(1)
      end

      it 'should return an object with fields from retrieve' do
        @result.class.should == subject
      end
      
      it 'should should have populated attributes in object' do
        expected = {
          :email_address => 'test@email.com',
          :first_name => 'First',
          :last_name => 'Last'
        }
        
        expected.each do |key, value|
          @result.attributes[key].should == value
        end
        
      end
      
      context 'find without a result' do
        
        before do
          mock = mock_eloqua_request(:retrieve, :contact_missing)
          @result = subject.find(5)
        end
        
        it 'should return false' do
          @result.should be_false
        end
        
      end

    end

  end
  
  context '#self.where' do
    
    let(:klass) do
      Class.new(subject) do
        map :C_EmailAddress => :email
      end
    end
    
    context "when successfuly finding single result with all fields" do
    
      let(:input) { {:email => 'james@lightsofapollo.com'} }
      let(:xml_body) do
        api = subject.api
        create_xml do |xml|
          xml.eloquaType do
            xml.template!(:entity, api.entity('Contact'))
          end
          xml.searchQuery("C_EmailAddress='james@lightsofapollo.com'")
          xml.pageNumber(1)
          xml.pageSize(200)
        end
      end
      
      before do
        mock = soap_fixture(:query, :contact_email_one)
        flexmock(subject.api).should_receive(:send_remote_request).with(:service, :query, xml_body).and_return(mock)
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
    
    context "when rows are not found" do
      let(:input) { {:email => 'james@lightsofapollo.com'} }
      let(:xml_body) do
        api = subject.api
        
        create_xml do |xml|
          xml.eloquaType do
            xml.template!(:entity, api.entity('Contact'))
          end
          xml.searchQuery("C_EmailAddress='james@lightsofapollo.com'")
          xml.pageNumber(1)
          xml.pageSize(200)
        end
      end
      
      before do
        mock = soap_fixture(:query, :contact_missing)
        flexmock(subject.api).should_receive(:send_remote_request).with(:service, :query, xml_body).and_return(mock)
        @results = klass.where(input)
      end
      
      specify { @results.should be_false }
      
    end
    
  end
  
  context "#self.update_entity" do
    
    context "when successfuly updating one row" do
      let(:input) { [1, {:C_EmailAddress => 'new'}] }
      let(:xml_body) do
        api = subject.api
        create_xml do |xml|
          xml.entities do
            xml.DynamicEntity do
              xml.template!(:dynamic_entity, api.entity('Contact'), '1', {
                :C_EmailAddress => 'new',                
              })
            end
          end
        end
      end

      before do
        mock = soap_fixture(:update, :contact_success)
        flexmock(subject.api).should_receive(:send_remote_request).with(:service, :update, xml_body).and_return(mock)
        @results = subject.update_entity(*input)        
      end
      
      it 'should return true' do
        @results.should be_true
      end
      
    end
    
  end

  context "#self.build_query" do
    
    context "when using a string" do
      
      let(:input) do
        "C_EmailAddress = 'test'"
      end
      
      it 'should return given value' do
        subject.build_query(input).should == input
      end
            
    end
    
    context 'when using a hash' do
            
      let(:klass) do
        Class.new(subject) do
          map :C_EmailAddress => 'email'
        end
      end
      
      it 'should generate query string using map_attribute on mapped attributes' do
        klass.build_query(:email => 'test').should == "C_EmailAddress='test'"
      end
      
      it 'should use given attribute name when none is mapped' do
        klass.build_query(:C_Company => 'company').should == "C_Company='company'"
      end
      
      it 'should join coniditons with and' do
        email_param = "C_EmailAddress='test'"
        company_param = "C_Company='company'"
        
        result = klass.build_query(:email => 'test', :C_Company => 'company')
        result.should include(email_param)
        result.should include(company_param)
        result.should include(' AND ')
      end
      
    end
    
  end

end
