require 'eloqua/api'
require 'eloqua/helper/attribute_map'
require 'active_model'
require 'active_support/core_ext/hash'

module Eloqua

  class RemoteObject

    include ActiveModel::MassAssignmentSecurity
    include ActiveModel::Naming
    include ActiveModel::Validations
    include ActiveModel::Conversion
    include ActiveModel::AttributeMethods
    
    # Because we never absolutely know what attributes are defined
    # We do not use define_attribute_method for dirty meaning #{attr}_changed? will not work
    # instead use the private methods provided by dirty IE: attribute_changed?(:attr)
    include ActiveModel::Dirty
    include Eloqua::Helper::AttributeMap
        
    DIRTY_PRIVATE_METHODS = [:attribute_was, :attribute_changed?, :attribute_change]
    DIRTY_PRIVATE_METHODS.each {|method| public method }

    delegate :api, :to => self
    delegate :request, :to => self
    delegate :client, :to => self
    
    class_attribute :primary_key, :remote_object_type, :attribute_types, :remote_object
    
    attr_reader :attributes

    self.attribute_types = {}.with_indifferent_access

    self.primary_key = 'id'
    self.remote_object_type = nil
      
    # If the remote flag is set to :remote (or true) the object
    # assumes that the attributes are from eloqua directly in their format (IE: C_EmailAddress)
    # it will then format them to a more ruby-ish key (:email_address) and then store the original name
    # This means if you do not have a #map for the object when you are creating it for the first time
    # the object cannot determine the original eloqua name
    def initialize(attr = {}, remote = false)
      @instance_reverse_keys = attribute_map_reverse.clone
      if(remote)
        @_persisted = true
        attr = map_attributes(attr)
      end
      @attributes = convert_attribute_values!(attr).with_indifferent_access
      if(@attributes.has_key?(primary_key) && @attributes[primary_key])
        @_persisted = true
      end
      
    end
    
    def persisted?
      @_persisted ||= false
    end

    def convert_attribute_values!(attributes)
      attributes.each do |key, value|
        attributes[key] = self.send(attribute_types[key][:import], key, value) if(attribute_types.has_key?(key))
      end
      attributes
    end
    

    private :map_attributes, :reverse_map_attributes
    
    # Persistance
    
    def create
      attrs = reverse_map_attributes(attributes)
      result = self.class.create_remote_object(attrs)
      if(result)
        @_persisted = true
        write_attribute(:id, result[:id])
        true
      else
        false
      end
    end
    
    def update
      update_attributes = changed.inject({}) do |map, attr|
        map[attr] = send(attr.to_sym)
        map
      end      
      attrs = reverse_map_attributes(update_attributes)
      self.class.update_remote_object(self.attributes[primary_key].to_i, attrs)      
    end
    
    def save(options = {})
      if(valid?)
        (persisted?) ? update : create
        true
      else
        false
      end
    end
    
    def update_attributes(attrs)
      attrs = sanitize_for_mass_assignment(attrs)
      attrs.each do |key, value|
        write_attribute(key, value)
      end
      save
    end
    
    # Magic
    
    # Monkey Patch. Rails uses a normal array for changed_attributes and
    # relys on method missing to provide the same type all the time
    def changed_attributes
      @changed_attributes ||= {}.with_indifferent_access
    end
    
    def read_attribute(attr)
      attributes[attr]
    end
    
    def write_attribute(attr, value)
      attribute_will_change!(attr) unless read_attribute(attr) == value
      attributes[attr] = value
    end
    
    def is_attribute_method?(method)
      attr = method.to_s.gsub(/\=$/, '')
      
      if(attributes.has_key?(attr) || attribute_map_reverse.has_key?(attr))
        attr_type = (method.to_s =~ /\=$/)? :write : :read
      else
        false
      end
    end    
    
    def id
      read_attribute(:id)
    end
        
    def method_missing(method, *args)
      attr_method = is_attribute_method?(method)
      attr = method.to_s.gsub(/\=$/, '')
      if(attr_method)
        case attr_method
          when :write then write_attribute(attr, *args)
          when :read then read_attribute(attr)
        end
      else
        super
      end
    end
    
    def respond_to?(method, *args)
      if(is_attribute_method?(method))
        true
      else
        super
      end
    end

    # Column type setting

    protected

    def export_boolean_checkbox(attr, value)
      if(!!value)
        'Yes'
      else
        'No'
      end
    end

    def import_boolean_checkbox(attr, value)
      if(value =~ /yes/i)
        value = true
      elsif(value =~ /no/i)
        value = false
      end
      value
    end

    class << self

      # Attribute types

      def attr_type_hash(name)
        {
          :type => name.to_sym,
          :import => "import_#{name}".to_sym,
          :export => "export_#{name}".to_sym
        }
      end

      def attr_checkbox(*attrs)
        options = attrs.extract_options!
        attrs.each do |column|
          attribute_types[column] = attr_type_hash(:boolean_checkbox)
        end
      end

      def api
        Eloqua::API
      end

      def client
        api.client(:service)
      end

      def request(method, *args)
        api.request(:service, method, *args)
      end
      
      # Eloqua CAN find multiple records from retrieve
      # but for our purpose this would only be confusing so only use
      # find for single records and use query for multiple results...
      def find(id)
        xml_query = api.builder do |xml|
          xml.object_type_lower!(remote_object) do
            xml.template!(:object_type, remote_object_type)
          end
          xml.ids do
            xml.template!(:int_array, [id])
          end
        end

        result = request(remote_service_method(:retrieve), xml_query)
        
        field_key = "#{remote_object}_fields".to_sym
        dynamic_key = "dynamic_#{remote_object}".to_sym
                
        if(result[dynamic_key] && result[dynamic_key][:field_value_collection])
          attribute_list = result[dynamic_key][:field_value_collection][field_key]
          attributes = {:id => result[dynamic_key][:id].to_i}
          attribute_list.each do |map|
            attributes[map[:internal_name]] = map[:value]
          end
          self.new(attributes, :remote)
        else
          false
        end
      end
      
      def remote_service_method(method)
        if(remote_object == :entity)
          method.to_sym
        else
          "#{method}_#{remote_object}".to_sym
        end
      end
      
      def remote_object_type_tag
        "#{remote_object}Type"
      end
      
      def remote_key_with_object(name)
        if(remote_object == :entity)
          name.to_sym
        else
          parts = name.to_s.split('_')
          "#{parts[0]}_#{remote_object}_#{parts[1]}".to_sym
        end
      end
      
      def dynamic_tag
        "Dynamic#{remote_object.to_s.camelize}".to_sym
      end
            
      def create_remote_object(attributes)
        xml_query = api.builder do |xml|
          xml.object_collection!(remote_object) do
            xml.dynamic_object!(remote_object) do
              xml.template!(:dynamic, remote_object, remote_object_type, nil, attributes)
            end
          end
        end
        
        result = request(remote_service_method(:create), xml_query)
        result = result[remote_key_with_object(:create_result)]
        
        if(result[:errors].nil? && result[:id])
          {:id => result[:id].to_i}
        else
          handle_remote_exception(result)
        end
      end
      
      def update_remote_object(entity_id, attributes)
        xml_query = api.builder do |xml|
          xml.object_collection!(remote_object) do
            xml.dynamic_object!(remote_object) do
              xml.template!(:dynamic, remote_object, remote_object_type, entity_id, attributes)
            end
          end
        end
                
        result = request(remote_service_method(:update), xml_query)
        result = result[remote_key_with_object(:update_result)]
        
        if(result[:success] && result[:id].to_s == entity_id.to_s)
          true
        else
          handle_remote_exception(result)
        end
      end
      
      def handle_remote_exception(response)
        exception = response[:errors][:error]
        
        error_code = exception[:error_code]
        message = exception[:message]
        
        error_message = sprintf("Eloqua Error: Code (%s) | Message: %s", error_code, message)
        
        if(error_code =~ /Duplicate/)
          raise(Eloqua::DuplicateRecordError, error_message)
        else
          raise(Eloqua::RemoteError, error_message)
        end
        false
      end
      
    end

  end
    
end