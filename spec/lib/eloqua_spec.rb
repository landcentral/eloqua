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
  
  context '#self.authenticate' do
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

  context "#self.format_results_for_array" do
    context "level 1 depth ending in single" do
      let(:input) do
        {
          :one => :hit
        }
      end

      let(:expected) { [:hit] }

      it 'should return expected' do
        result = subject.format_results_for_array(input, :one)
        result.should == expected
      end

    end

    context "level 3 depth ending in multiple" do

      let(:input) do
        {
          :one => {
            :two => {
              :three => [:hit, :hit]
            }
          }
        }
      end

      let(:expected) { [:hit, :hit] }

      it 'should return expected' do
        result = subject.format_results_for_array(input, :one, :two, :three)
        result.should == expected
      end
    end

    context "level 3 depth ending in single" do

      let(:input) do
        {
          :one => {
            :two => {
              :three => [:hit]
            }
          }
        }
      end

      let(:expected) { [:hit] }

      it 'should return expected' do
        result = subject.format_results_for_array(input, :one, :two, :three)
        result.should == expected
      end
    end
  end

end