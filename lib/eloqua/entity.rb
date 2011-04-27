require 'eloqua/remote_object'

module Eloqua
  
  class Entity < RemoteObject
    
    self.remote_group = :entity

    def list_memberships
      self.class.list_memberships(id)
    end

    def add_membership(asset)
      asset.add_member(self)
    end

    def remove_membership(asset)
      asset.remove_member(self)
    end

    class << self

      def list_memberships(id)
        api.list_memberships(remote_type, id)
      end

      def where(conditions = nil, fields = [], limit = 200, page = 1)
				if(conditions)
					query = where
					conditions.each do |key, value|
						query.on(key, '=', value)
					end
					query.fields(fields) if fields
					query.limit(limit)
					query.page(page)
					results = query.all
					if(results.blank?)
						false
					else
						results
					end
				else
					Eloqua::Query.new(self)
				end
      end      
    end
    
  end
end
