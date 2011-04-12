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
      
      def remote_object_type
        "#{@remote_type}Type"
      end

      def dynamic_type
        "Dynamic#{@remote_type.to_s.camelize}"
      end

      def tag_with_type(tag)
        "#{tag}_#{@remote_type}".to_sym
      end

      def remote_method(method)
        if(@remote_type == :entity)
          method.to_sym
        else
          ("#{method}_#{@remote_type}").to_sym
        end
      end 
      
    end
  end
end