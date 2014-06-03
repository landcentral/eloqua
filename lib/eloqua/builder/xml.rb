require 'eloqua/builder/templates'

module Eloqua

  module Builder

    # This could (and likely should) be submitted as a patch for
    # the main builder class
    class Xml < ::Builder::XmlMarkup

      include ::Eloqua::Builder::Templates

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

      # For use with add/remove membership
      define_builder_template :object do |xml, object_type, type, id|
        xml.tag!(object_type) do
          xml.object_type!(object_type) do
            xml.template!(:object_type, type)
          end
          xml.Id(id)
        end
      end

      # For use with the entity function
      define_builder_template :object_type do |xml, object|
        xml.ID(object[:id])
        xml.Name(object[:name])
        xml.Type(object[:type])
      end

      # defines entity attribute fields for use in update/create
      define_builder_template :fields do |xml, object_type, entity_attributes|
        entity_attributes.each do |attribute, value|
          xml.tag!("#{object_type.to_s.camelize}Fields") do
            xml.InternalName(attribute.to_s)
            xml.Value(value)
          end
        end
      end

      # Dynamic entity for update/create/etc...

      define_builder_template :dynamic do |xml, object_type, type, id, attributes|
        xml.tag!("#{object_type.to_s.camelize}Type") do
          xml.template!(:object_type, type)
        end

        xml.FieldValueCollection do
          xml.template!(:fields, object_type, attributes)
        end

        xml.Id(id) if id
      end

      def initialize(options = {}, &block)
        super
        @namespace = nil
        @namespace = options[:namespace].to_sym if options[:namespace]
        yield self if ::Kernel.block_given?
      end

      def builder_template(name, *args)
        ::Eloqua::Builder::Xml.builder_template(name, *args)
      end

      def self.create(options = {}, &block)
        new(options, &block).target!
      end

      def template!(template, *args)
        builder_template(template, *args).call(self)
      end

      def dynamic_object!(sym, *args, &block)
        tag!("Dynamic#{sym.to_s.camelize}", *args, &block)
      end

      def object_type!(sym, *args, &block)
        tag!("#{sym.to_s.camelize}Type", *args, &block)
      end

      def object_type_lower!(sym, *args, &block)
        tag!("#{sym}Type", *args, &block)
      end

      def object_collection!(sym, *args, &block)
        tag!("#{sym.to_s.pluralize.downcase}", *args, &block)
      end

      # Extend to allow default namespace
      def method_missing(sym, *args, &block)
        if(@namespace && !args.first.kind_of?(::Symbol))
          args.unshift(sym.to_sym)
          sym = @namespace
        end
        super(sym, *args, &block)
      end

    end

  end

end
