require 'savon'

require 'active_support/core_ext/class'
require 'active_support/concern'
require 'active_support/core_ext/module/delegation'

require 'eloqua/builder/xml'
require 'eloqua/exceptions'

module Eloqua

  class Api

    # The namespace for Eloqua Array objects
    XML_NS_ARRAY = 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'

    # WSDLs are from 3-30-2011
    WSDL = {
      :service => File.dirname(__FILE__) + '/wsdl/service.wsdl',
      :data =>  File.dirname(__FILE__) + '/wsdl/data.wsdl',
      :email =>  File.dirname(__FILE__) + '/wsdl/email.wsdl'
    }

    class << self

      delegate :define_builder_template, :to => Eloqua::Builder::Xml
      delegate :builder_template, :to => Eloqua::Builder::Xml
      delegate :builder_templates, :to => Eloqua::Builder::Xml

      cattr_accessor :last_request, :last_response

      @@clients = {}

      def reset_clients
        @@clients = {}
      end

      def clients
        @@clients
      end

      # There are three wsdl types for eloqua
      # 1. Service
      # 2. Data
      # 3. Email
      def client(type)
        if(!Eloqua.user || !Eloqua.password)
          raise('Eloqua.user or Eloqua.password is not set see Eloqua.authenticate')
        end
        clients[type] ||= Savon::Client.new do
          wsdl.document = WSDL[type]
          wsse.credentials Eloqua.user, Eloqua.password
        end
      end

      def builder(&block)
        Eloqua::Builder::Xml.create(:namespace => :wsdl, &block)
      end

      def remote_type(name, type = 'Base', id = 0)
        {
          :name => name,
          :type => type,
          :id => id
        }
      end

      def request(type, name, soap_body = nil, &block)
        result = send_remote_request(type, name, soap_body, &block)
        
        self.last_request = client(type).soap.to_xml if client(type).soap
        self.last_response = result.to_xml if result.respond_to?(:to_xml)

        if(result)
          result = result.to_hash
          response_key = "#{name}_response".to_sym
          result_key = "#{name}_result".to_sym
          if(result.has_key?(response_key))
            result = result[response_key]
          end
          if(result.has_key?(result_key))
            result = result[result_key]
          end
        end
        result
      end


      # Sends remote request and returns a response object
      def send_remote_request(type, name, soap_body = nil, &block)
        request = client(type).request(:wsdl, name) do
          soap.namespaces["xmlns:arr"] = XML_NS_ARRAY
          soap.element_form_default = :qualified
          soap.body = soap_body if soap_body
          instance_eval(&block) if block_given?
        end
        request
      end

    end
  end

end
