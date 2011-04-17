# Eloqua API for Ruby

Currently supports the majority of the ServiceAPI for Eloqua.

The Service API supports the CURD of Entities (Contacts, etc..) and Assets (ContactGroups)

This should be considered an early beta of the final product.

## Layers

There are two layers to the software.

Eloqua::Api & Eloqua::Api::Service which are the barebones of the requests.
They offer a fast low-level methods to interact with Eloqua.

Eloqua::Asset and Eloqua::Entity (which descend from Eloqua::RemoteObject) provide an ActiveRecord like
interface to your Eloqua Database.

For example to create a fully operational model to manage your contacts all you need is the below:

    class Contact < Eloqua::Entity
      self.remote_type = api.remote_type('Contact')
    end

### TODO

  - (inline) Documentation
  - Guide
  - Email API (ongoing)
