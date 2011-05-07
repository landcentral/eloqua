## 0.2.3
 - Added last_request, last_response to Eloqua::API

 - Added wrapper around the Savon SOAP and HTTP exceptions.
   Savon should disable its error handling and let Eloqua raise its own
   errors by using `Savon::configure {|config| config.raise_errors =
   false }`. This allows us to capture last_request and last_response
   even when there is a Soap or HTTP fault

## 0.2
 - Abstracted out majority of requests into Eloqua::Api::Service

 - Added Eloqua::Api::Service for a lightweight interface to Eloqua used
	 by other components like RemoteObject, Entity and Asset

 - Eloqua::Query advanced Query builder with support for paging through
	 the entire set of records spanning multiple requests


## 0.1
 - Initial Release

 - Support for Service Api
