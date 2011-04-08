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
      
    end
  end
end