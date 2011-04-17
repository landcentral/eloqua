require 'spec_helper'

describe Eloqua::Asset do
  
  subject do
    Class.new(Eloqua::Asset) do
      self.remote_type = api.remote_type('ContactGroupName', 'ContactGroup', 0)
      def self.name
        'ContactGroup'
      end
    end
  end

  let(:entity) do
    Class.new(Eloqua::Entity) do
      self.remote_type = api.remote_type('Contact')
    end
  end

  let(:object) { subject.new(:id => 1) }


  context "#member_operation" do

    let(:input) { [entity.new(:id => 1  )] }

    context "when given non entity" do
      it "should raise argument error" do
        lambda do
          object.send(:member_operation, :add_group_member, nil)
        end.should raise_exception(ArgumentError, /Eloqua\:\:Entity/)
      end
    end

    context "when given unpersisted entity" do
      it "should raise argument error" do
        lambda do
          object.send(:member_operation, :add_group_member, Eloqua::Entity)
        end.should raise_exception(ArgumentError, /Eloqua\:\:Entity/)
      end
    end

    context "#add_member" do
      it 'should delegate call to member_operation' do
        flexmock(object).should_receive(:member_operation).with(:add_group_member, *input).once
        object.add_member(*input)
      end
    end

    context "#remove_member" do
      it 'should delegate call to member_operation' do
        flexmock(object).should_receive(:member_operation).with(:remove_group_member, *input).once
        object.remove_member(*input)
      end
    end

  end
  
  specify { subject.remote_group.should == :asset }

  it_behaves_like 'class level delegation of remote operations for', :asset

end