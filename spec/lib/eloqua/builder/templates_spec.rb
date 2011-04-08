require "spec_helper"

describe Eloqua::Builder::Templates do

  let(:xml) do
    Eloqua::Builder::Xml.new
  end

  subject do
    klass = Class.new
    klass.send(:include, Eloqua::Builder::Templates)
    klass
  end

  context "#define_builder_template" do

    before do
      subject.define_builder_template :iterator do |xml, list|
      end
    end

    it 'should have saved block in builder_templates' do
      subject.builder_templates.size.should == 1
    end

    it 'should be able to access block' do
      subject.builder_templates[:iterator].class.should == Proc
    end

  end

  context '#builder_template' do

    context 'passing no arguments to template' do

      before do
        subject.define_builder_template :bigwow do |xml|
          xml.big_wow("BANG!")
        end
      end

      it 'should be able to use template to create xml' do
        output = xml.omg(&subject.builder_template(:bigwow))
        output.strip.should == '<omg><big_wow>BANG!</big_wow></omg>'
      end

    end

    context 'passing arguments to template' do

      before do
        subject.define_builder_template :long do |xml, list|
          list.each do |element|
            xml.tag!(element[0], element[1])
          end
        end
      end

      it 'should take arguments and build output' do
        output = xml.long(&subject.builder_template(:long, [ ['big', 'value'], ['small', 'value'] ]))
        output.strip.should == '<long><big>value</big><small>value</small></long>'
      end

    end
    
  end

end
