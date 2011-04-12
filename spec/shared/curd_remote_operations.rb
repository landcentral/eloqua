shared_examples_for "supports CURD remote operations" do |remote_type|
  
  before do
    @remote_type = remote_type
  end
  
  let(:remote_type) { @remote_type }
  
  context "#self.find" do
    
    context "successful find with all fields" do
      let(:xml_body) do
        create_xml do |xml|
          xml.object_type_lower!(remote_type) do
            xml.template!(:object_type, subject.remote_object_type)
          end
          xml.ids do
            xml.template!(:int_array, [1])
          end
        end
      end

      before do
        mock = soap_fixture(remote_method(:retrieve), :contact_single)
        flexmock(subject.api).should_receive(:send_remote_request).with(:service, remote_method(:retrieve), xml_body).and_return(mock)
        @result = subject.find(1)
      end

      it 'should return an object with fields from retrieve' do
        @result.class.should == subject
      end
      
      it 'should should have populated attributes in object' do
        expected = {
          :email_address => 'test@email.com',
          :first_name => 'First',
          :last_name => 'Last',
          :id => 1
        }
        
        expected.each do |key, value|
          @result.send(key).should == value
        end
        
      end
      
      context 'find without a result' do
        
        before do
          mock = mock_eloqua_request(remote_method(:retrieve), :contact_missing)
          @result = subject.find(5)
        end
        
        it 'should return false' do
          @result.should be_false
        end
        
      end

    end

  end
  
  context '#self.create_remote_object' do
    
    let(:input) { [{:C_EmailAddress => 'create'}] }
    
    context 'when successfuly creating one record' do
      
      let(:xml_body) do
        api = subject.api
        create_xml do |xml|
          xml.entities do
            xml.tag!(dynamic_type) do
              xml.template!(:dynamic, remote_type, api.remote_object_type('Contact'), nil, {
                :C_EmailAddress => 'create',                
              })
            end
          end
        end
      end
      
      before do
        mock = soap_fixture(remote_method(:create), :contact_success)
        flexmock(subject.api).should_receive(:send_remote_request).with(:service, remote_method(:create), xml_body).and_return(mock)
        @results = subject.create_remote_object(*input)
      end
      
      
      it 'should return {:id => 1}' do
        @results[:id].should == 1
      end
                        
    end
    
    context "when the record is duplicate" do
      before do
        mock = soap_fixture(remote_method(:create), :contact_duplicate)
        flexmock(subject.api).should_receive(:send_remote_request).and_return(mock)
      end
      
      it 'should raise duplicate error exception' do
        lambda { subject.create_remote_object(*input) }.should raise_exception(Eloqua::DuplicateRecordError)
      end
      
    end    
    
  end
  
  context "#self.update_remote_object" do
    
    context "when successfuly updating one record" do
      let(:input) { [1, {:C_EmailAddress => 'new'}] }
      let(:xml_body) do
        api = subject.api
        create_xml do |xml|
          xml.entities do
            xml.tag!(dynamic_type) do
              xml.template!(:dynamic, remote_type, subject.remote_object_type, '1', {
                :C_EmailAddress => 'new',                
              })
            end
          end
        end
      end

      before do
        mock = soap_fixture(remote_method(:update), :contact_success)
        flexmock(subject.api).should_receive(:send_remote_request).with(:service, remote_method(:update), xml_body).and_return(mock)
        @results = subject.update_remote_object(*input)        
      end
      
      it 'should return true' do
        @results.should be_true
      end
      
    end
    
  end
  
end