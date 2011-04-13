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
        flexmock(Eloqua::API).should_receive(:send_remote_request).returns(mock)
      end
                        
      def mock_api_request(method = nil, xml_body = nil, result = nil)
        if(!xml_body && !result)
          # No with expectation
          result = method
          flexmock(subject).should_receive(:request).\
                              and_return(result)      
        else
          # with expectation
          flexmock(subject).should_receive(:request).\
                              with(method, xml_body).\
                              and_return(result)      
        end
      end
      
      def xml!(&block)
        subject.api.builder(&block)
      end
      
      def remote_object_type
        "#{remote_object}Type"
      end

      def dynamic_type
        "Dynamic#{remote_object.to_s.camelize}"
      end

      def tag_with_type(tag)
        "#{tag}_#{remote_object}".to_sym
      end

      def remote_method(method)
        if(remote_object == :entity)
          method.to_sym
        else
          ("#{method}_#{remote_object}").to_sym
        end
      end 
      
    end
  end
end