require 'spec_helper'

describe Eloqua::Builder::Xml do

  subject { Eloqua::Builder::Xml }
  
  # We might reveal methods on builder so create blank subclass
  subject {
    Class.new(Eloqua::Builder::Xml) do
      reveal(:class)
      reveal(:is_a?)
    end
  }

  let(:xml) do
    subject.new(:namespace => 'wsdl')
  end  
  
  it "should include Eloqua::Builder::Templates" do
    subject.should include(Eloqua::Builder::Templates)
  end
  
  it 'should allow a block during new providing self' do
    subject.new do |xml|
      xml.is_a?(subject)
    end
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
  
  context "#self.create" do
    
    let(:klass) do
      Class.new(subject) do
        define_builder_template(:zomg) do |xml|
          xml.wow('zomg')
        end
      end
    end
    
    let(:xml_body) do
      '<big>1</big><wow>zomg</wow>'
    end
    
    it 'should produce expected output' do
      out = klass.create do |xml|
        xml.big('1')
        xml.template!(:zomg)
      end
      out.should == xml_body
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
        @output = subject.create(&subject.builder_template(template, *@args))
      end

      it "should return :expected output from template :#{template}" do
        @output.should == expected.to_s
      end
    end

    let(:entity) do
      Eloqua::API.entity('Contact')
    end

    context ':dynamic_entity' do

      let(:args) do
        [Eloqua::API.entity('Contact'), 124194, {:C_Company => 'Lights of Apollo LLC'}]
      end

      let(:expected) do
        subject.create do |xml|
          xml.EntityType(&subject.builder_template(:entity, entity))
          xml.FieldValueCollection(&subject.builder_template(:entity_fields, args[2]))
          xml.Id(args[1])
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
        subject.create do |xml|
          xml.EntityFields do
            xml.InternalName('C_EmailAddress')
            xml.Value('james@localhost')
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
        subject.create do |xml|
          xml.ID('0')
          xml.Name('Contact')
          xml.Type('Base')
        end
      end

      it_behaves_like 'expected template output', :entity

    end

    context ":array" do

      let(:input) do
        [1, 'string', '1', 'string']
      end
      let(:expected) do
        subject.create do |xml|
          xml.arr(:int, '1')
          xml.arr(:string, 'string')
          xml.arr(:string, '1')
          xml.arr(:string, 'string')
        end
      end

      it_behaves_like 'expected template output', :array

    end

    context ":int_array" do


      let(:input) do
        [1, 'ouch', 2, 'wow', '3']
      end

      let(:expected) do
        subject.create do |xml|
          xml.arr(:int, 1)
          xml.arr(:int, 2)
          xml.arr(:int, 3)
        end
      end

      it_behaves_like 'expected template output', :int_array

    end

  end  


end