module Eloqua
  class Entity
    class Contact < Eloqua::Entity
      
      map :C_EmailAddress => :email
      map :ContactID => :id
      
      self.entity_type = 'Contact'
      
    end
  end
end