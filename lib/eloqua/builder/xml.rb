require 'eloqua/builder/templates'

module Eloqua

  module Builder

    # This could (and likely should) be submitted as a patch for
    # the main builder class
    class Xml < ::Builder::XmlMarkup
      
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
      
      delegate :builder_template, :to => self
      

      def initialize(options = {}, &block)
        super
        @namespace = nil
        @namespace = options[:namespace].to_sym if options[:namespace]
        yield self if block_given?
      end
      
      def self.create(options = {}, &block)
        new(options, &block).target!
      end
            
      def template!(template, *args)
        builder_template(template, *args).call(self)
      end


      # Extend to allow default namespace
      def method_missing(sym, *args, &block)
        if(@namespace && !args.first.kind_of?(Symbol))
          args.unshift(sym.to_sym)
          sym = @namespace
        end
        super(sym, *args, &block)
      end

    end

  end
  
end