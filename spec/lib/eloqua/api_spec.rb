require 'spec_helper'
require 'pp'


describe Eloqua::Api do

  subject { Eloqua::Api }

  before do
    subject.reset_clients
  end
  
  context '#builder' do
    
    it 'should call Eloqua::Builder::Xml.create' do
      flexmock(Eloqua::Builder::Xml).should_receive(:create).once
      subject.builder
    end
        
  end

  context "#request" do

    context "When returning multiple records" do

      before do
        mock_response(:retrieve, :contact_multiple)
        @response = subject.request(:service, :retrieve) do
        end
      end

      it 'should return dynamic entity key as the top level hash' do
        @response.should have_key(:dynamic_entity)
      end

      it "should have stored response in #last_response" do
        body = Savon::Spec::Fixture.load(:retrieve, :contact_multiple)
        subject.last_response.should == body
      end

      it "should have stored response in #last_request" do
        subject.last_request.should_not be_blank
      end
      

    end

  end
  
  context "#raise_response_errors" do

    context "when response given is an HTTP error" do
      it "should raise Eloqua::HTTPError" do
        
      end
    end

    context "when response given is a SOAP Fault" do

      it "should raise an SoapError" do
        mock_response(:query, :fault)
        lambda { @response = subject.request(:service, :query) }.should raise_exception(Eloqua::SoapError)
      end

    end

  end

  context "#client" do
    
    context 'when no Eloqua.user or Eloqua.password is set' do
      
      before do
        Eloqua.authenticate(nil, nil)
      end
      
      it 'should raise RuntimeError about missing user or password' do
        lambda { subject.client(:service) }.should raise_exception(RuntimeError, 'Eloqua.user or Eloqua.password is not set see Eloqua.authenticate')
      end      
      
    end

    before do
      @connection = subject.client(:email)
    end

    it 'should return a Savon::Client' do
      @connection.class.should == Savon::Client
    end

    it "should return a savon instance of the given wsdl type" do
      @connection.wsdl.instance_variable_get(:@document).should == subject::WSDL[:email]
    end

    it 'should have wsse username set to Eloqua.user constant' do
      @connection.wsse.username.should == Eloqua.user
    end

    it 'should have wsse password set to Eloqua.password constant' do
      @connection.wsse.password.should == Eloqua.password
    end

    it "should have an :arr namespace for arrays" do
      
    end

  end

  context "#remote_type" do

    before do
      @entity = subject.remote_type('Contact')
    end

    it "should be a hash" do
      @entity.class.should == Hash
    end

    it "should have an ID of 0" do
      @entity[:id].should == 0
    end

    it "should have a Name equal to Contact" do
      @entity[:name].should == 'Contact'
    end

    it "should have Type equal to Base" do
      @entity[:type].should == 'Base'
    end

  end

end
