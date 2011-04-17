module Eloqua
  module RSpec
    module Helper
      
      def soap_fixture(type, name, code = 200, headers = {})
        body = Savon::Spec::Fixture.load(type, name)
        httpi = HTTPI::Response.new(code, headers, body)
        Savon::SOAP::Response.new(httpi)
      end
  
      def mock_eloqua_request(type, name, code = 200, headers = {})
        mock = soap_fixture(type, name, code, headers)
        flexmock(Eloqua::Api).should_receive(:send_remote_request).returns(mock)
      end
                        
      def mock_api_request(method = nil, xml_body = nil, result = nil)
        mocked_object = subject

        if(mocked_object.respond_to?(:api))
          mocked_object = mocked_object.api
        end
        
        if(!xml_body && !result)
          # No with expectation
          result = method
          flexmock(mocked_object).should_receive(:request).\
                              and_return(result).once
        else
          # with expectation
          flexmock(mocked_object).should_receive(:request).\
                              with(method, xml_body).\
                              and_return(result).once      
        end
      end
      
      def xml!(&block)
        Eloqua::Api.builder(&block)
      end

      def group_name
        (respond_to?(:remote_object))? remote_object : group
      end
      
      def remote_object_type
        "#{group_name}Type"
      end

      def dynamic_type
        "Dynamic#{group_name.to_s.camelize}"
      end

      def tag_with_type(tag)
        "#{tag}_#{group_name}".to_sym
      end

      def remote_method(method)
        if(group_name == :entity)
          method.to_sym
        else
          ("#{method}_#{group_name}").to_sym
        end
      end 
      
    end
  end
end
