require 'eloqua/api'
require 'eloqua/helper/attribute_map'
require 'active_model'
require 'active_support/core_ext/hash'

module Eloqua

  class Entity

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
    
    class_attribute :primary_key, :entity_type, :attribute_types
    
    attr_reader :attributes

    self.attribute_types = {}.with_indifferent_access

    self.primary_key = 'id'
    self.entity_type = nil
      
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
      result = self.class.create_entity(attrs)
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
      self.class.update_entity(self.attributes[primary_key].to_i, attrs)      
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
      
      # This method does ~NOT~ sanitize input like active record does
      def build_query(where)
        if(where.is_a?(String))
          where
        elsif(where.is_a?(Hash))
          parts = []
          where.each do |attr, value|
            parts << "#{eloqua_attribute(attr)}='#{value}'"
          end
          parts.join(" AND ")
        end
      end
      
      def where(conditions, fields = [], limit = 200, page = 1)
        xml_query = api.builder do |xml|
          xml.eloquaType do
            xml.template!(:entity, api.entity(entity_type))
          end
          xml.searchQuery(build_query(conditions))
          xml.pageNumber(page)
          xml.pageSize(limit)
        end
        
        result = request(:query, xml_query)
        if(result[:entities])
          records = []
          result = result[:entities]
          if(result[:dynamic_entity].is_a?(Hash))
            result[:dynamic_entity] = [result[:dynamic_entity]]
          end
          result = result[:dynamic_entity]
          result.each do |entity|
            record_attrs = {}
            entity_id = entity[:id]
            entity[:field_value_collection][:entity_fields].each do |entity_attr|
              record_attrs[entity_attr[:internal_name]] = entity_attr[:value]
            end
            record_attrs[primary_key] = entity_id
            records << self.new(record_attrs, :remote)
          end
          records
        else
          false
        end
      end

      # Eloqua CAN find multiple records from retrieve
      # but for our purpose this would only be confusing so only use
      # find for single records and use query for multiple results...
      def find(id)
        xml_query = api.builder do |xml|
          xml.entityType do
            xml.template!(:entity, api.entity(entity_type))
          end
          xml.ids do
            xml.template!(:int_array, [id])
          end
        end

        result = request(:retrieve, xml_query)
        if(result[:dynamic_entity] && result[:dynamic_entity][:field_value_collection])
          attribute_list = result[:dynamic_entity][:field_value_collection][:entity_fields]
          attributes = {}
          attribute_list.each do |map|
            attributes[map[:internal_name]] = map[:value]
          end
          self.new(attributes, :remote)
        else
          false
        end
      end
      
      def create_entity(attributes)
        xml_query = api.builder do |xml|
          xml.entities do
            xml.DynamicEntity do
              xml.template!(:dynamic_entity, api.entity(entity_type), nil, attributes)
            end
          end
        end
        
        result = request(:create, xml_query)
        result = result[:create_result]
              
        if(result[:errors].nil? && result[:id])
          {:id => result[:id].to_i}
        else
          handle_remote_exception(result)
        end
      end
      
      def update_entity(entity_id, attributes)
        xml_query = api.builder do |xml|
          xml.entities do
            xml.DynamicEntity do
              xml.template!(:dynamic_entity, api.entity(entity_type), entity_id, attributes)
            end
          end
        end
                
        result = request(:update, xml_query)
        result = result[:update_result]
        
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