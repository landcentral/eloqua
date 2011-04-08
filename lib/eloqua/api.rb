require 'savon'

require 'active_support/core_ext/class'
require 'active_support/concern'

require 'eloqua/builder/xml'
require 'eloqua/builder/templates'

module Eloqua

  class API

    # The namespace for Eloqua Array objects
    XML_NS_ARRAY = 'http://schemas.microsoft.com/2003/10/Serialization/Arrays'

    # WSDLs are from 3-30-2011
    WSDL = {
      :service => File.dirname(__FILE__) + '/wsdl/service.wsdl',
      :data =>  File.dirname(__FILE__) + '/wsdl/data.wsdl',
      :email =>  File.dirname(__FILE__) + '/wsdl/email.wsdl'
    }

    include Eloqua::Builder::Templates

    # XML Templates

    # For use with strings and integers may do strange
    # things on the SOAP server side if given a float
    define_builder_template :array do |xml, array|
      array.each do |element|
        tag = 'string'
        if(element.is_a?(String))
          tag = 'string'
        elsif(element.is_a?(Numeric))
          tag = 'int'
        end
        xml.arr(tag.to_sym, element)
      end
    end

    define_builder_template :int_array do |xml, array|
      array.each do |element|
        unless(element.is_a?(Numeric))
          element = element.to_i
          if(element == 0 || !element)
            next
          end
        end
        xml.arr(:int, element)
      end
    end

    # For use with the entity function
    define_builder_template :entity do |xml, entity|
      xml.ID(entity['ID'])
      xml.Name(entity['Name'])
      xml.Type(entity['Type'])
    end

    # defines entity attribute fields for use in update/create
    define_builder_template :entity_fields do |xml, entity_attributes|
      entity_attributes.each do |attribute, value|
        xml.EntityFields do
          xml.InternalName(attribute.to_s)
          xml.Value(value)
        end
      end
    end

    # Dynamic entity for update/create/etc...

    define_builder_template :dynamic_entity do |xml, type, id, attributes|
      xml.EntityType(&builder_template(:entity, type))
      xml.FieldValueCollection(&builder_template(:entity_fields, attributes))
      xml.Id(id)
    end


    class << self

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
        Eloqua::Builder::Xml.new(:namespace => :wsdl, &block)
      end

      def entity(name, type = 'Base', id = 0)
        {
          'Name' => name,
          'Type' => type,
          'ID' => id
        }
      end

      def request(type, name, soap_body = nil, &block)
        result = send_remote_request(type, name, soap_body, &block)
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
        client(type).request(:wsdl, name) do
          soap.namespaces["xmlns:arr"] = XML_NS_ARRAY
          soap.element_form_default = :qualified
          soap.body = soap_body if soap_body
          instance_eval(&block) if block_given?
        end
      end

    end
  end

end