require 'spec_helper'
require 'pp'


describe Eloqua::API do

  subject { Eloqua::API }

  before do
    subject.reset_clients
  end

  it "should include Eloqua::Builder::Templates" do
    subject.should include(Eloqua::Builder::Templates)
  end
  
  context '#builder' do
    specify { subject.builder.is_a?(Eloqua::Builder::Xml).should be_true }
  end

  context "#request" do

    context "When returning multiple records" do

      before do
        mock_eloqua_request(:retrieve, :contact_multiple)
        @response = subject.request(:service, :retrieve) do
        end
      end

      it 'should return dynamic entity key as the top level hash' do
        pp @response
        @response.should have_key(:dynamic_entity)
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

  context "#entity" do

    before do
      @entity = subject.entity('Contact')
    end

    it "should be a hash" do
      @entity.class.should == Hash
    end

    it "should have an ID of 0" do
      @entity['ID'].should == 0
    end

    it "should have a Name equal to Contact" do
      @entity['Name'].should == 'Contact'
    end

    it "should have Type equal to Base" do
      @entity['Type'].should == 'Base'
    end

  end

  context 'xml templates' do

    share_examples_for "expected template output" do |template|

      before do
        @args = []
        if(respond_to?(:args))
          @args = args
        elsif respond_to?(:input)
          @args = [input]
        end
        builder = subject.builder
        @output = builder.wrap(&subject.builder_template(template, *@args))
      end

      it "should return :expected output from template :#{template}" do
        @output.should == expected.to_s
      end
    end

    let(:entity) do
      subject.entity('Contact')
    end

    let(:builder) do
      subject.builder
    end

    context ':dynamic_entity' do

      let(:args) do
        [subject.entity('Contact'), 124194, {:C_Company => 'Lights of Apollo LLC'}]
      end

      let(:expected) do
        builder.wrap do
          builder.EntityType(&subject.builder_template(:entity, entity))
          builder.FieldValueCollection(&subject.builder_template(:entity_fields, args[2]))
          builder.Id(args[1])
        end
      end

      it_behaves_like 'expected template output', :dynamic_entity

    end

    context ':entity_fields' do

      let(:input) do
        list = {}
        list[:C_EmailAddress] = 'james@localhost'
        list
      end


      let(:expected) do
        builder.wrap do
          builder.EntityFields do
            builder.InternalName('C_EmailAddress')
            builder.Value('james@localhost')
          end
        end
      end

      it_behaves_like 'expected template output', :entity_fields

    end

    context ':entity' do

      let(:input) do
        subject.entity('Contact')
      end

      let(:expected) do
        builder.wrap do
          builder.ID('0')
          builder.Name('Contact')
          builder.Type('Base')
        end
      end

      it_behaves_like 'expected template output', :entity

    end

    context ":array" do

      let(:input) do
        [1, 'string', '1', 'string']
      end
      let(:expected) do
        builder.wrap do
          builder.arr(:int, '1')
          builder.arr(:string, 'string')
          builder.arr(:string, '1')
          builder.arr(:string, 'string')
        end
      end

      it_behaves_like 'expected template output', :array

    end

    context ":int_array" do


      let(:input) do
        [1, 'ouch', 2, 'wow', '3']
      end

      let(:expected) do
        builder.wrap do
          builder.arr(:int, 1)
          builder.arr(:int, 2)
          builder.arr(:int, 3)
        end
      end

      it_behaves_like 'expected template output', :int_array

    end

  end

  context "test requests"  do

   # it "should be able to retrieve a row" do
   #   body = {
   #      :entityType => entity('Contact'),
   #      :ids => {'arr:int' => [900000000]},
   #      :fieldNames => {'arr:string' => ['ContactID', 'C_EmailAddress']},
   #      :order! => [:entityType, :ids, :fieldNames]
   #   }
   #   
   #   r = subject.request(:service, :retrieve, body)
   #   pp r.to_hash
   # end
   # 
   # it "should be able to retrieve a asset row" do
   #   body = {
   #      :assetType => subject.entity('ContactGroup'),
   #      :ids => {'arr:int' => [112]},
   #      :order! => [:assetType, :ids]
   #   }
   #   asset = {}
   #   #pp subject.send_remote_request(:service, :retrieve_asset, body)
   # end

   # it "should be able to run a query by email address" do
   #   request = subject.request(:service, :query) do
   #     soap.body = {
   #         :eloquaType => entity('Contact'),
   #         :searchQuery => "C_EmailAddress='*@lightsofapollo.com' AND C_EmailAddress='iam.revelation@gmail.com'",
   #         :fieldNames => {'arr:string' => ['C_Arizona1', 'C_California1', 'C_EmailAddress', 'ContactID']},
   #         :pageNumber => '1',
   #         :pageSize => '20',
   #         :order! => [:eloquaType, :searchQuery, :fieldNames, :pageNumber, :pageSize]
   #     }
   #   end
   #   pp request.to_hash
   # end

    it "should be able to update james@lightsofapollo.com's contact information" do
  
        builder = subject.builder
  
        template = subject.builder_template(:dynamic_entity, subject.entity('Contact'), '124194', {
            :C_FirstName => 'James',
            :C_Arizona1 => 'No',
            :C_California1 => 'Yes'
        })
  
        request_body = builder.entities do
          builder.DynamicEntity(&template)
        end
  
        request = subject.send_remote_request(:service, :update) do
          soap.body = request_body
        end

        puts request.to_xml
      end

  end

end