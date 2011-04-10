require 'spec_helper'

describe Eloqua::Helper::AttributeMap do
  
  subject do
    Class.new do
      include Eloqua::Helper::AttributeMap
    end
  end
  
  it_behaves_like 'uses attribute map'  
  
end