require 'spec_helper'

shared_examples_for 'remote operation that converts attribute values' do |operation|

  let(:method) { "#{operation}_object".to_sym }

  let(:klass) do
    Class.new(subject) do
      map :C_California1 => :california
      attr_checkbox(:california)
    end
  end
  
  context "when #{operation.to_s.pluralize} object" do
    it 'should convert value before saving' do
      if(operation == :update)
        object = klass.new(:id => 1)
        flexmock(object.class).should_receive(method).\
          with(1, {'C_California1' => 'Yes'}).once
      else
        object = klass.new
        flexmock(object.class).should_receive(method).\
          with({'C_California1' => 'Yes'}).once
      end

      
      object.california = true
      object.save
    end

  end

end

describe Eloqua::RemoteObject do
    
  subject do
    Class.new(Eloqua::RemoteObject) do
      self.remote_type = Eloqua::Api.remote_type('Contact')
      self.remote_group = :entity
      
      def self.name
        'ContactEntity'
      end
      
    end
  end

  let(:remote_type) do
    subject.api.remote_type('Contact')
  end
  
  context "#self.remote_group" do
    specify { subject.remote_group.should == :entity }
  end
  
  it_behaves_like 'uses attribute map'
  it_behaves_like 'class level delegation of remote operations for', :entity

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


  end

  context "#reload" do

    let(:new_attr) { {:C_EmailAddress => 'new'} }

    before do
      flexmock(subject).should_receive(:find_object, 1).\
        and_return(new_attr).\
        once

      @object = subject.new({:id => 1, :C_EmailAddress => 'old'}, :remote)
      @object.reload
    end

    it 'should have updated email to new' do
      @object.email_address.should == 'new'
    end

    it 'should not be dirty' do
      @object.attribute_changed?(:email_address).should be_false
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
  
  context 'dirty attributes' do
    
    let(:klass) do
      Class.new(subject) do
        map :C_EmailAddress => :email
      end
    end
    
    let(:object) do
      klass.new
    end
    
    it 'should call attribute_will_change! when using attribute_write' do
      flexmock(object).should_receive(:attribute_will_change!).with("email").once
      object.email = 'email'
    end
    
    context 'when email has changed' do
      before do
        object.email = 'old'
        object.email = 'new'
      end
      
      it 'should have old value available via attribute_was' do
        object.attribute_was(:email).should == 'old'
      end

      it 'should have old and new value available via attribue_change' do
        object.attribute_change(:email).should == ['old', 'new']
      end
      
      it 'should provide a list of all changed attributes via changed' do
        object.changed.should == ['email']
      end
    end
  end
  
  context "when persisting object" do
    let(:input) do
      {:email => 'email', :name => 'first'}
    end

    let(:klass) do
      Class.new(subject) do
        map :C_EmailAddress => :email
        map :C_FirstName => :name
        map :ContactID => :id
        
        validates_presence_of :email
      end
    end

    let(:object) { klass.new(:id => 1) }

    let(:expected) do
      {
        :C_EmailAddress => 'email',
        :C_FirstName => 'first'
      }.with_indifferent_access
    end

    
    it_behaves_like 'remote operation that converts attribute values', :update
    
    context "#update" do

      before do
        flexmock(klass).should_receive(:update_object).\
                           with(1, expected).and_return(true)

        object.email = 'email'
        object.name = 'first'
        
        @result = object.update
      end

      it 'should call update entity to make the api call' do
        @result.should be_true
      end

      specify { object.email.should == 'email' }
      specify { object.name.should == 'first' }
    end    
   
    
    it_behaves_like 'remote operation that converts attribute values', :create 

    context "#create" do
      let(:object) { klass.new }
      
      before do
        flexmock(klass).should_receive(:create_object).\
                           with(expected).and_return({:id => 1})
                            
        object.email = 'email'
        object.name = 'first'
        @result = object.create
      end

      it 'should call update entity to make the api call' do
        @result.should be_true
      end

      specify { object.id.should == 1 }
      specify { object.email.should == 'email' }
      specify { object.name.should == 'first' }
    end
    
    context "#save" do
            
      context 'when save will create' do
        let(:object) do
          klass.new(:email => 'james@lightsofapollo.com')
        end
        
        before do
          flexmock(klass).should_receive(:create_object).\
                             with({'C_EmailAddress' => 'james@lightsofapollo.com'}).\
                             and_return({:id => 1}).once
          object.save
        end
        
        it 'should now be persisted?' do
          object.should be_persisted
        end
        
        it 'should now have an id' do
          object.id.should == 1
        end
        
      end
      
      context 'when save will update' do
        
        let(:object) do
          klass.new(:id => 1, :email => 'james@lightsofapollo.com')
        end
        
        before do
          flexmock(klass).should_receive(:update_object).\
                             with(1, {'C_EmailAddress' => 'new'}).\
                             and_return(true).once

          object.email = 'new'
          object.save
        end
        
        it 'should now be persisted?' do
          object.should be_persisted
        end
        
        it 'should have updated email address to "new"' do
          object.email.should == 'new'
        end
                
      end
      
      context "when record is invalid" do
        
        let(:object) do
          klass.new(:id => 1)
        end
        
        it 'should not be valid' do
          object.should_not be_valid
        end
        
        it 'should return false when saving' do
          object.save.should be_false
        end
        
      end
      
    end    
    
    context "#update_attributes" do
      context "when successfuly updating record" do
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
            :email => 'email',
          }.with_indifferent_access
        end      

        before do
          flexmock(klass).should_receive(:update_object).\
                             with(1, {'C_EmailAddress' => 'email'}).and_return(true)

          @result = object.update_attributes(input)      
        end

        it 'should call update entity to make the api call' do
          @result.should be_true
        end

        specify { object.email.should == 'email' }
        specify { object.name.should == 'james' }        
        
      end
      
      
      context 'when updating attributes of invalid object' do
        
        let(:input) do
          {}
        end
        
        let(:object) { klass.new }
        
        before do
          flexmock(object).should_receive(:create).never
          flexmock(object).should_receive(:update).never
        end
        
        it 'should be invalid' do
          object.should_not be_valid
        end
        
        it 'should return false' do
          object = klass.new
          object.update_attributes(input).should be_false
        end
        
      end
      
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

  context '#convert_attribute_values' do
    let(:klass) do
      Class.new(subject) do
        map :C_California1 => :california
        attr_checkbox(:california)
      end
    end

    context 'when :import' do
      it 'should call import_boolean_checkbox' do
        object = klass.new(:california => 'Yes')
        flexmock(object.class).should_receive(:import_boolean_checkbox).with(:california, 'Yes').and_return(true)
        attrs = object.convert_attribute_values(object.attributes)
        attrs[:california].should === true
      end
    end

    context 'when :export' do

      it 'should call export_boolean_checkbox' do
        object = klass.new(:california => 'Yes')
        flexmock(object.class).should_receive(:export_boolean_checkbox).with(:california, true).and_return('Yes')
        attrs = object.convert_attribute_values(object.attributes, :export)
        attrs[:california].should === 'Yes'
      end
 
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
        map :C_California1 => :california
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
    
  context "#self.api" do
    it 'should have api on the class level' do
      subject.api.should == Eloqua::Api::Service
    end
  end

	context "#api" do
		 it "should have api on the instance level" do
			 subject.new.api.should == Eloqua::Api::Service
		 end
	end

end
