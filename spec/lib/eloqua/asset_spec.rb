require 'spec_helper'

describe Eloqua::Asset do
  
  subject do
    Class.new(Eloqua::Asset) do
      self.remote_object_type = Eloqua::Api.remote_object_type('ContactGroupName', 'ContactGroup', 0)
      def self.name
        'ContactGroup'
      end
    end
  end
  
  specify { subject.remote_object.should == :asset }

  it_behaves_like 'class level delegation of remote operations for', :asset

end