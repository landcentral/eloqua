module Eloqua  
  module Helper
    
    module AttributeMap
      
      extend ActiveSupport::Concern
      
      included do
        class_attribute :attribute_map, :attribute_map_reverse
        
        attr_reader :instance_reverse_keys
        
        self.attribute_map = {}.with_indifferent_access
        self.attribute_map_reverse = {}.with_indifferent_access

        class << self
          alias_method_chain :inherited, :clone_attributes
        end
                
      end
      
      module ClassMethods
        
        def inherited_with_clone_attributes(klass)
          klass.attribute_map = attribute_map.clone
          klass.attribute_map_reverse = attribute_map_reverse.clone
          inherited_without_clone_attributes(klass) if method_defined?(:inherited_without_clone_attributes)
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
 
      end
      
      module InstanceMethods
        
        def map_attributes(attributes)
          @instance_reverse_keys ||= attribute_map_reverse.clone
          results = {}.with_indifferent_access

          attributes.each do |key, value|
            formatted_key = attribute_map.fetch(key) { key.to_s.gsub(/^C_/, '').underscore }
            @instance_reverse_keys[formatted_key] = key
            results[formatted_key] = value
          end
          results
        end

        def reverse_map_attributes(attributes)
          results = {}.with_indifferent_access
          attributes.each do |key, value|
            results[@instance_reverse_keys[key]] = value
          end
          results
        end
                  
      end
      
    end
    
  end
end