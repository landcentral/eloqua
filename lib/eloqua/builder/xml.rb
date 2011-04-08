module Eloqua

  module Builder

    # This could (and likely should) be submitted as a patch for
    # the main builder class
    class Xml < ::Builder::XmlMarkup

      def initialize(options = {})
        super
        @namespace = nil
        @namespace = options[:namespace].to_sym if options[:namespace]
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