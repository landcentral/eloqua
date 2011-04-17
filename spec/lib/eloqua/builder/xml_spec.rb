require 'spec_helper'

describe Eloqua::Builder::Xml do
  
  def xml!(&block)
    subject.create(&block)
  end

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
  
  # Entity/Asset Helpers
  
  context '#dynamic_object!' do
    
    let(:expected) { '<DynamicAsset>content</DynamicAsset>' }
    
    it 'should return expected xml' do
      xml! {|xml| xml.dynamic_object!(:asset, 'content') }.should == expected
    end
    
  end
  
  context '#object_type!' do
    let(:expected) { '<AssetType>content</AssetType>' }
    
    it 'should return expected xml' do
      xml! {|xml| xml.object_type!(:asset, 'content') }.should == expected
    end
    
  end
  
  context '#object_type_lower!' do
    let(:expected) { '<assetType>content</assetType>' }
    
    it 'should return expected xml' do
      xml! {|xml| xml.object_type_lower!(:asset, 'content') }.should == expected
    end
    
  end  
  
  context '#object_collection!' do
    let(:expected) { "<entities><one>1</one></entities>" }
    it 'should return expected xml' do
      xml! {|xml| xml.object_collection!(:entity) { xml.one('1') } }.should == expected
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
      Eloqua::Api.remote_type('Contact')
    end
    
    context ':object' do
      let(:args) do
        ['random', Eloqua::Api.remote_type('Contact'), 1]
      end
      
      let(:expected) do
        xml! do |xml|
          xml.random do
            xml.RandomType do
              xml.template!(:object_type, Eloqua::Api.remote_type('Contact'))
            end
            xml.Id(1)
          end
        end
      end
      
      it_behaves_like 'expected template output', :object
      
    end

    context ':dynamic' do

      let(:args) do
        ['entity', Eloqua::Api.remote_type('Contact'), 124194, {:C_Company => 'Lights of Apollo LLC'}]
      end

      let(:expected) do
        subject.create do |xml|
          xml.EntityType do
            xml.template!(:object_type, entity)
          end
          xml.FieldValueCollection do
            xml.template!(:fields, 'entity', args[3])
          end
          xml.Id(args[2])
        end
      end

      it_behaves_like 'expected template output', :dynamic

    end

    context ':fields' do

      let(:args) do
        ['entity', input]
      end

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

      it_behaves_like 'expected template output', :fields

    end

    context ':entity' do

      let(:input) do
        Eloqua::Api.remote_type('Contact')
      end

      let(:expected) do
        subject.create do |xml|
          xml.ID('0')
          xml.Name('Contact')
          xml.Type('Base')
        end
      end

      it_behaves_like 'expected template output', :object_type

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
