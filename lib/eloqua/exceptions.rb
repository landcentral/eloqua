class Eloqua::RemoteError < StandardError; end
class Eloqua::DuplicateRecordError < Eloqua::RemoteError; end

class Eloqua::SoapError < Savon::SOAP::Fault; end
class Eloqua::HTTPError < Savon::HTTP::Error; end
