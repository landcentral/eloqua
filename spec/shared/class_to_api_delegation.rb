# This is for testing the xml syntax given to the remote objects
# Actual response tests (with fixtures) should be done in the 
# Entity or Asset spec's

shared_examples_for "class level delegation of remote operations for" do |remote_object|
  
  before do
    @remote_object = remote_object
  end
  
  let(:email) { 'test@email.com' }
  
  let(:dynamic_key) { ("dynamic_#{remote_object}".to_sym) }
  let(:field_key) { "#{remote_object}_fields".to_sym }

  group_delegation = Eloqua::Api::Service.group_methods
  type_delegation = Eloqua::Api::Service.type_methods
  group_type_delegation = Eloqua::Api::Service.group_type_methods

  group_delegation.each do |method|
    context "#self.#{method}" do
      it "should delegate #{method} to Eloqua::Api::Service with group name" do
        flexmock(Eloqua::Api::Service).should_receive(method).\
            with(subject.remote_object).once
        subject.send(method)
      end
    end
  end

  group_type_delegation.each do |method|
    context "#self.#{method}" do
      it "should delegate #{method} to Eloqua::Api::Service with group name" do
        flexmock(Eloqua::Api::Service).should_receive(method).\
            with(subject.remote_object, subject.remote_object_type).once
        subject.send(method)
      end
    end
  end

  type_delegation.each do |method|
    context "#self.#{method}" do
      it "should delegate #{method} to Eloqua::Api::Service with group name" do
        flexmock(Eloqua::Api::Service).should_receive(method).\
            with(subject.remote_object_type).once
        subject.send(method)
      end
    end
  end

end