require 'eloqua/remote_object'

module Eloqua
  
  class Asset < RemoteObject
    
    self.remote_object = :asset
    
    class << self
      
      def entity_association_xml(asset_id, entity, entity_id)
        if(entity.is_a?(Class) && entity.ancestors.include?(Eloqua::RemoteObject))
          entity = entity.remote_object_type
        end

        xml_query = api.builder do |xml|
          xml.template!(:object, :entity, entity, entity_id)
          xml.template!(:object, :asset, remote_object_type, asset_id)
        end
      end
      
      def entity_asset_operation(request_method, asset_id, entity, entity_id)
        xml_query = entity_association_xml(asset_id, entity, entity_id)
        result = request(request_method.to_sym, xml_query)
        if(result[:success])
          true
        elsif(result[:errors])
          handle_remote_exception(result)
        else
          false
        end        
      end
      
      # Adds entity to this Asset
      def add_group_member(asset_id, entity, entity_id)
        entity_asset_operation(:add_group_member, asset_id, entity, entity_id)
      end
      
      # Removes entity to this Asset
      def remove_group_member(asset_id, entity, entity_id)
        entity_asset_operation(:remove_group_member, asset_id, entity, entity_id)     
      end
      
    end
    
  end
  
end