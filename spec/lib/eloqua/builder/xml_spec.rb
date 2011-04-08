require 'spec_helper'

describe Eloqua::Builder::Xml do

  subject { Eloqua::Builder::Xml }

  let(:xml) do
    subject.new(:namespace => 'wsdl')
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


end