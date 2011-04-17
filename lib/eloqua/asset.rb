require 'eloqua/remote_object'

module Eloqua
  
  class Asset < RemoteObject
    
    self.remote_group = :asset

    def add_member(entity)
      member_operation(:add_group_member, entity)
    end

    def remove_member(entity)
      member_operation(:remove_group_member, entity)
    end
    
    private

    def member_operation(method, entity)
      unless (entity.is_a?(Eloqua::Entity))
        raise(ArgumentError, "Must pass a Eloqua::Entity")
      end
      unless (entity.persisted?)
        raise(ArgumentError, "Cannot add member Entity has not been saved. (!entity.persisted?")
      end
      api.send(method, remote_object_type, id, entity.remote_object_type, entity.id)
    end

  end
  
end