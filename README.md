# Eloqua API for Ruby

Currently supports the majority of the ServiceAPI for Eloqua.

The Service API supports the CURD of Entities (Contacts, etc..) and Assets (ContactGroups)

Through {Eloqua::Query} supports advanced queries spanning multiple
requests.

## At a low level

For low level requests we offer the {Eloqua::Api::Service} (other Api's
soon) with the "api" you can make calls like this:

		Eloqua::Api::Service.describe_type(:asset, 'ContactGroup')

The majority of the functions in the api require a "group" which
is either :entity or :asset.

The other common object you will need to have on hand is the "type"
both entities and assets in Eloqua have types. Types look like this:

		{
			:id => 1,
			:type => 'Base',
			:name => 'Contact'
		}

The most important thing is the :type. See
 {Eloqua::Api::Service.describe} and {Eloqua::Api::Service.describe_type}
eloqua provides describe and describe_type for gathering information of
types the what fields those types provide. Types are similar to SQL
tables.

Also see {Eloqua::Api.remote_type} a helper method for generating the
hash above.

Here is an example of a find request (which requires a group and type)

		group = :entity
		type = Eloqua::Api.remote_type('Contact') 
		# => {:id => 1, :type => 'Base', :name => 'Contact'}

		# Executes a Retreive SOAP call
		record = Eloqua::Api::Service.find_object(
			group,
			type,
			1 # object id
		)
		
		record
		# Keys are internal_name of fields
		# => {:id => 1, :C_EmailAddress => 'email@address.com', ...}

Through the low level api we offer the following Eloqua SOAP methods


### Supported low level requests

- CURD (+ Find)
	- Retrieve[Asset] => {Eloqua::Api::Service.find_object}
	- Update[Asset] => {Eloqua::Api::Service.update_object}
	 - Create[Asset] => {Eloqua::Api::Service.create_object}
	- Delete[Asset] => {Eloqua::Api::Service.delete_object}

- Describing Fields and Types
	- Describe[Asset|Entity]Type => {Eloqua::Api::Service.describe_type}
	- Describe[Asset|Entity] => {Eloqua::Api::Service.describe}
	- List[Asset|Entity]Types => {Eloqua::Api::Service.list_types}

- Memberships (Contact Groups)
	 - AddGroupMember  => {Eloqua::Api::Service.add_group_member}
	 - RemoveGroupMember => {Eloqua::Api::Service.remove_group_member}
	 - ListGroupMembership => {Eloqua::Api::Service.list_memberships}

## At a high level (Models)

Through {Eloqua::Entity} and {Eloqua::Asset} we offer base classes
for modeling both entities and assets. 

Both inherit from {Eloqua::RemoteObject} which implements a number of
ActiveModel features (persistance, dirty attributes, validations mass
assignment security)

To create a model (Sorry, no generator yet!) its as simple as inheriting
from entity or asset and then specifying a type.

		class Contact < Eloqua::Entity
			self.remote_type = api.remote_type('Contact')
		end

With just this you have instant access to the data with familiar
{Eloqua::RemoteObject#save save}, {Eloqua::RemoteObject#update_attributes update attributes}, {Eloqua::RemoteObject#persisted? persisted?}, {Eloqua::RemoteObject etc}

Magic accessor are also created for "map(ped)" attributes or objects
that where retreived remotely. See below

### Attribute Mapping


First you should note that C\_ (thats `/^C\_/`) is replaced from
all attribute names and they are underscored (`.underscore`) for instance:

		eloqua_does_this = 'C_EmailAddress'
		you_do_this = your_model.email_addres

Because of the naming schema for Eloqua "internal_name" there where many
times where I felt I would rather use a different name that was easier
to type and remember. With this in mind I created attribute mapping.

Here we map C_EmailAddress to email

		class Contact < Eloqua::Entity
			self.remote_type = api.remote_type('Contact')
			# use the FULL original name including C_ and CamelCase
			map :C_EmailAddress => :email
		end

Now we can reference our contacts email with `.email`

### Saving your data

When you retrieve object from Eloqua through {Eloqua::RemoteObject#find
find} or through {Eloqua::Query} that object will be aware of all of its 
attributes (or the ones selected in the query) and will map them back to
Eloqua's original `internal_name` scheme during the save. 

When you create a new object however you need define those fields through map.

		class Contact < Eloqua::Entity
			self.remote_type = api.remote_type('Contact')
		end

		record = Contact.new
		record.email_address = 'new@email.com' # ERROR

		class Contact < Eloqua::Entity
			self.remote_type = api.remote_type('Contact')
			map :C_EmailAddress => :email_address
		end

		record = Contact.new
		record.email= 'new@email.com'
		record.save # SUCCESS
		
		# This will successfuly map .email => C_EmailAddress

### What about class methods?

Models support all functionality provided in {Eloqua::Api::Service}
through {Eloqua.delegate_with_args}.

Where a group is argument is needed by the low level api the
model will provide it with its group (entity or asset). 
Where a type is needed the model will provide the models
{Eloqua::RemoteObject.remote_type remote_type}

		
		# delegates to Eloqua::Api::Service.describe(:entity, Contact.remote_type)
		Contact.describe 

		# delegates to Eloqua::Api::Service.describe_type(:entity, 'Contact')
		# Notice that the second argument is now the first and is required
		Contact.describe_type('Contact')


## Queries

Eloqua provides a method for accessing your data.

There are a few important things you need to know about this first.

1. You may only query 200 records at once. You may pull in more via
	 pages in a seperate request (pagination)

2. You may only make a Query request once per second.
	 (Concurency is a no-go in some situations)

3. I would highly recommend limiting the returned rows. 
	 The limit on other requests is very high so you can make many more
	 find/update/create/delete, etc.. requests then you can queries.

	 I would reccomend gathering EloquaIDs through query and then manipulating
	 data through those EloquaIDs in other operations

Through {Eloqua::Query} you can search through your Eloqua database.

Given we have this Contact class:

		class Contact < Eloqua::Contact
			self.remote_type = api.remote_type('Contact')
			
			map :C_EmailAddress => :email
			map :C_DateCreated => :created_at
			map :C_DateModified => :updated_at

		end

We can then search for all email addresses in the lightsofapollo.com
domain. 

		# Entity.where is an alias for Eloqua::Query.new(Contact)
		query = Contact.where
		query.on(:email, '=', '*@lightsofapollo.com') # * is a wildcard
		query.all # makes request returns Array

Or all contacts created today

		query.clear_conditions! # resets request
		query.on(:created_at, '>', Time.now.strftime('%Y-%m-%d'))
		query.each do |record| # this will also make request and iterator through results
			...
		end

Or something more complex

		query.clear_conditions!
		query.on(:email, '=', '*@lightsofapollo.com').\ # email search
				  on(:updated_at, '>', '2011-01-01').\ # updated at >
					limit(1).\ # we only want one record
					fields([:email, 'ContactID']) # only return a record with the email and id fields populated

		query.all

As you might have guessed query will return an Array of Objects of the
type given. 

		# Will return ContactGroup.new(s)
		Eloqua::Query.new(ContactGroup)


### For queries that match over 200 records

For queries that span multiple requests (and you want all records at once) 
use {Eloqua::Query#each_page} each page functions just like each but
will make consecutive requests to fetch all pages. It also takes an
optional max pages parameter which allows you to limit the number of
pages to fetch and/or pause and resume requests.

## TODO

  - (inline) Docs [DONE FOR QUERY]
  - Guide
  - Email API (ongoing)
