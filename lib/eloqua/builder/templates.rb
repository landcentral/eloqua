module Eloqua
  module Builder

    module Templates

      extend ActiveSupport::Concern

      included do
        class_attribute :builder_templates
        self.builder_templates = {}
      end

      module ClassMethods

        def builder_template(name, *args)
          template = builder_templates[name]
          Proc.new do |xml|
            template.call(xml, *args)
          end
        end

        def define_builder_template(name, &block)
          builder_templates[name] = block
        end
      end

    end


  end
end