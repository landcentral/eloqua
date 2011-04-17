# This is for testing the xml syntax given to the remote objects
# Actual response tests (with fixtures) should be done in the 
# Entity or Asset spec's

shared_examples_for "supports CURD remote operations" do |remote_object|
  
  before do
    @remote_object = remote_object
  end
  
  let(:remote_object) { @remote_object }
  let(:email) { 'test@email.com' }
  
  let(:dynamic_key) { ("dynamic_#{remote_object}".to_sym) }
  let(:field_key) { "#{remote_object}_fields".to_sym }
  
  context "#list_types" do
    let(:remote_method) { "list_#{remote_object}_types".to_sym }
    
    before do
      mock_eloqua_request(remote_method, :success).with(:service, remote_method, nil)
    end
        
    it 'should return results as an array' do
      result = subject.list_types
      result.class.should == Array
    end
        
  end
    
  context "#describe" do
    let(:remote_method) { "describe_#{remote_object}".to_sym }    
    
    let(:xml_body) do
      xml! do |xml|
        xml.object_type_lower!(remote_object) do
          xml.template!(:object_type, subject.remote_object_type)
        end
      end
    end
    
    before do
      mock_eloqua_request(remote_method, :success).with(:service, remote_method, xml_body)
      @result = subject.describe
    end
    
    it 'should have fields in the top level in result as an array' do
      @result.should have_key(:fields)
      @result[:fields].class.should == Array
    end
    
  end
    
  context "#self.find" do
    
    let(:find_result) do
      {
        dynamic_key => {
          :field_value_collection => {
            field_key => [{
              :internal_name => 'C_EmailAddress',
              :value => email
            }]
          },
          :id => '1'
        }
      }
    end
    
    context "successful find with all fields" do
      let(:xml_body) do
        xml! do |xml|
          xml.object_type_lower!(remote_object) do
            xml.template!(:object_type, subject.remote_object_type)
          end
          xml.ids do
            xml.template!(:int_array, [1])
          end
        end
      end

      before do
        mock_api_request(remote_method(:retrieve), xml_body, find_result)                            
        @result = subject.find(1)
      end

      it 'should return an object with fields from retrieve' do
        @result.class.should == subject
      end
      
      it 'should should have populated attributes in object' do
        expected = {
          :email_address => email,
          :id => 1
        }
        expected.each do |key, value|
          @result.send(key).should == value
        end
        
      end
      
      context 'find without a result' do
        
        before do
          mock = mock_api_request({
            dynamic_key => nil
          })
          
          @result = subject.find(5)
        end
        
        it 'should return false' do
          @result.should be_false
        end
        
      end

    end

  end
  
  context '#self.create_object' do
    
    let(:result_key) { subject.key_with_object(:create_result) }    
    let(:input) { [{:C_EmailAddress => 'create'}] }
    let(:create_result) do
      {
        result_key => {
          ("#{remote_object}_type").to_sym => subject.remote_object_type,
          :errors => nil,
          :id => 1
        }
      }
    end
    
    context 'when successfuly creating one record' do
      
      let(:xml_body) do
        api = subject.api
        xml! do |xml|
          xml.object_collection!(remote_object) do
            xml.dynamic_object!(remote_object) do
              xml.template!(:dynamic, remote_object, subject.remote_object_type, nil, {
                :C_EmailAddress => 'create',                
              })
            end
          end
        end
      end
      
      before do
        mock_api_request(remote_method(:create), xml_body, create_result)
        @results = subject.create_object(*input)
      end
      
      
      it 'should return {:id => 1}' do
        @results[:id].should == 1
      end
                        
    end
    
    context "when the record is duplicate" do
      
      let(:create_result) do
        {
          result_key => {
            ("#{remote_object}_type").to_sym => subject.remote_object_type,
            :errors => {
              :error => {
                :error_code => 'DuplicateValue',
                :message => 'You are attempting to create a duplicate entity.'
              }
            }
          }
        }
      end
      
      before do
        mock_api_request(create_result)
      end
      
      it 'should raise duplicate error exception' do
        lambda { subject.create_object(*input) }.should raise_exception(Eloqua::DuplicateRecordError)
      end
      
    end    
    
  end
  
  context "#self.update_object" do
    
    
    let(:result_key) { subject.key_with_object(:update_result) }
    
    let(:update_result) do
      {
        result_key => {
          ("#{remote_object}_type").to_sym => subject.remote_object_type,
          :errors => nil,
          :id => 1,
          :success => true
        }
      }
    end
    
    context "when successfuly updating one record" do
      let(:input) { [1, {:C_EmailAddress => 'new'}] }
      let(:xml_body) do
        xml! do |xml|
          xml.object_collection!(remote_object) do
            xml.dynamic_object!(remote_object) do
              xml.template!(:dynamic, remote_object, subject.remote_object_type, '1', {
                :C_EmailAddress => 'new',                
              })
            end
          end
        end
      end

      before do
        mock_api_request(remote_method(:update), xml_body, update_result)
        @results = subject.update_object(*input)
      end
      
      it 'should return true' do
        @results.should be_true
      end
      
    end
    
  end
  
  context "#self.delete_object" do
    
    context "when given single int" do
      let(:result_key) { subject.key_with_object(:delete_result) }
      
      let(:delete_result) do
        {
          result_key => {
            ("#{remote_object}_type").to_sym => subject.remote_object_type,
            :errors => nil,
            :id => 1,
            :success => true
          }
        }
      end
      let(:input) { 1 }
      let(:xml_body) do
        xml! do |xml|
          xml.object_type_lower!(subject.remote_object) do
            xml.template!(:object_type, subject.remote_object_type)
          end
          xml.ids do
            xml.template!(:int_array, [input])
          end
        end
      end
      
      before do
        mock_api_request(remote_method(:delete), xml_body, delete_result)
        @result = subject.delete_object(1)
      end
      
      it 'should return an array of deleted ids' do
        @result.should == [1]
      end
      
    end
    
    context 'when given an array' do
      it 'should return an array of deleted ids' do
        # Pending....
      end
    end
    
  end
  
end