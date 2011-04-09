require 'spec_helper'

describe Eloqua::Builder::Xml do

  subject { Eloqua::Builder::Xml }

  let(:xml) do
    subject.new(:namespace => 'wsdl')
  end  
  
  it "should include Eloqua::Builder::Templates" do
    subject.should include(Eloqua::Builder::Templates)
  end

  context "when default namespace options is set" do
    
    let(:xml) do
      subject.new(:namespace => 'wsdl')
    end

    it 'should output the default namespace with tag' do
      output = xml.entities {}
      output.strip.should == '<wsdl:entities></wsdl:entities>'
    end

    it 'should allow us to override the default namespace' do
      output = xml.arr(:int) {}
      output.strip.should == '<arr:int></arr:int>'
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
        builder = subject.new
        @output = builder.wrap(&subject.builder_template(template, *@args))
      end

      it "should return :expected output from template :#{template}" do
        @output.should == expected.to_s
      end
    end

    let(:entity) do
      Eloqua::API.entity('Contact')
    end

    let(:builder) do
      subject.new
    end

    context ':dynamic_entity' do

      let(:args) do
        [Eloqua::API.entity('Contact'), 124194, {:C_Company => 'Lights of Apollo LLC'}]
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
        Eloqua::API.entity('Contact')
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


end