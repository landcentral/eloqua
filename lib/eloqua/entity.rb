require 'eloqua/api'
require 'active_model'
require 'active_support/core_ext/hash'

module Eloqua

  class Entity

    include ActiveModel::MassAssignmentSecurity
    include ActiveModel::Naming
    include ActiveModel::Validations
    include ActiveModel::Conversion


    delegate :api, :to => self
    delegate :request, :to => self
    delegate :client, :to => self
    
    class_attribute :attribute_map, :attribute_map_reverse,
                    :primary_key, :entity_type, :attribute_types

    attr_reader :attribute_keys_to_eloqua
    attr_reader :attributes

    self.attribute_map = {}.with_indifferent_access
    self.attribute_map_reverse = {}.with_indifferent_access
    self.attribute_types = {}.with_indifferent_access

    self.primary_key = 'id'
    self.entity_type = nil


    def self.inherited(subclass)
      subclass.attribute_map = self.attribute_map.clone
      subclass.attribute_map_reverse = self.attribute_map_reverse.clone      
    end


    # If the remote flag is set to :remote (or true) the object
    # assumes that the attributes are from eloqua directly in their format (IE: C_EmailAddress)
    # it will then format them to a more ruby-ish key (:email_address) and then store the original name
    # This means if you do not have a #map for the object when you are creating it for the first time
    # the object cannot determine the original eloqua name
    def initialize(attr = {}, remote = false)
      @attribute_keys_to_eloqua = attribute_map_reverse.clone
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

    def map_attributes(attributes)
      results = {}.with_indifferent_access

      attributes.each do |key, value|
        formatted_key = attribute_map.fetch(key) { key.to_s.gsub(/^C_/, '').underscore }
        @attribute_keys_to_eloqua[formatted_key] = key
        results[formatted_key] = value
      end
      results
    end

    def reverse_map_attributes(attributes)
      results = {}.with_indifferent_access
      attributes.each do |key, value|
        results[@attribute_keys_to_eloqua[key]] = value
      end
      results
    end
    

    private :map_attributes, :reverse_map_attributes
    
    # Data 
    
    def update_attributes(attrs)
      attrs = sanitize_for_mass_assignment(attrs)
      attrs.each do |key, value|
        write_attribute(key, value)
      end
      
      attrs = reverse_map_attributes(attrs)
      self.class.update_entity(self.attributes[primary_key].to_i, attrs)
    end
    
    # Magic
    
    def read_attribute(attr)
      attributes[attr]
    end
    
    def write_attribute(attr, value)
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

      
      def eloqua_attribute(attribute)
        (attribute_map_reverse.fetch(attribute) { attribute }).to_s
      end

      def map_attribute(attribute)
        attribute_map.fetch(attribute) { attribute.to_s }
      end

      # This shoud always be used over directly editing attribute_map
      def map(hash)
        hash.each do |key, value|
          value = value.to_sym
          key = key.to_sym
          
          attribute_map[key] = value
          attribute_map_reverse[value] = key
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
        xml_query = ""
        xml_query = api.builder.eloquaType(&api.builder_template(:entity, api.entity(entity_type)))
        xml_query += api.builder.searchQuery(build_query(conditions))
        # implement fields
        xml_query += api.builder.pageNumber(page)
        xml_query += api.builder.pageSize(limit)
        
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
        xml_query = api.builder.entityType(&api.builder_template(:entity, api.entity(entity_type)))
        xml_query += api.builder.ids(&api.builder_template(:int_array, [id]))

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
        
      end
      
      def update_entity(entity_id, attributes)
        template = api.builder_template(:dynamic_entity, api.entity(entity_type), entity_id, attributes)
        builder = api.builder
        xml_query = builder.entities do
          builder.DynamicEntity(&template)
        end
        
        result = request(:update, xml_query)
        result = result[:update_result]
        
        if(result[:success] && result[:id].to_s == entity_id.to_s)
          true
        else
          # TODO Raise Error here..
          false
        end
      end

    end

  end
    
end