module Eloqua
  module ApiDelegation

    extend ActiveSupport::Concern

    included do
      @@group_methods = {}
      @@type_methods = {}

      cattr_reader :group_methods
      cattr_reader :type_methods
    end

    def delegate(object, group, type)
      
    end

    def delegate_group_method(method, group)

    end

    def delegate_type_method(method, group, type)

    end

    def group_methods(*methods)

    end

    def type_methods(*methods)
      
    end

  end
end


class Eloqua::Entity

  include Eloqua::ApiDelegation

  self << class
    delegate_to_api(Eloqua::Api::Service, :remote_group, :  )
  end

end