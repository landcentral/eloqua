require 'spec_helper'

describe Eloqua do
  
  context '#self.configure' do
    it 'should provide self' do
      save = nil
      Eloqua.configure do |config|
        config.should == Eloqua
      end
    end
  end
  
  context '#authenicate' do
    before do
      Eloqua.authenticate('user', 'pass')
    end
    
    it 'should have set username to user' do
      Eloqua.user.should == 'user'
    end
    
    it 'should have set password to pass' do
      Eloqua.password.should == 'pass'
    end
    
  end

end