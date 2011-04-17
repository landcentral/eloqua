require 'spec_helper'

class EloquaSpecReceving
  class << self
    def one_argument(from_delg, arg)

    end

    def one_argument2(from_delg, arg)

    end

    def three_argument(from_delg1, from_delg2, arg)

    end

    def three_argument2(from_delg1, from_delg2, arg)

    end

  end
end

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

  context "#self.delegate_with_args" do

    let(:receiving) do
      EloquaSpecReceving
    end

    let(:sending) do
      Class.new do
        class << self
          def one
            1
          end

          def two
            2
          end
        end
      end
    end

    context 'with multiple delegated methods and single argument method' do
      before do
        Eloqua.delegate_with_args(sending, receiving, [:one_argument, :one_argument1], [:two])
      end

      specify { sending.should respond_to(:one_argument) }
      specify { sending.should respond_to(:one_argument1) }

      it 'should delegate method arguments to receiving' do
        flexmock(receiving).should_receive(:one_argument).with(2, 'arg').once
        sending.one_argument('arg')
      end

      it 'should delegate method arguments to receiving on other methods' do
        flexmock(receiving).should_receive(:one_argument1).with(2, 'arg').once
        sending.one_argument1('arg')
      end

    end

    context 'with multiple delegated methods and arguments' do
      before do
        Eloqua.delegate_with_args(sending, receiving, [:three_argument, :three_argument1], [:one, :two])
      end

      specify { sending.should respond_to(:three_argument) }
      specify { sending.should respond_to(:three_argument1) }

      it 'should delegate method arguments to receiving' do
        flexmock(receiving).should_receive(:three_argument).with(1, 2, 'arg').once
        sending.three_argument('arg')
      end

      it 'should delegate method arguments to receiving on other methods' do
        flexmock(receiving).should_receive(:three_argument1).with(1, 2, 'arg').once
        sending.three_argument1('arg')
      end

    end


  end

end