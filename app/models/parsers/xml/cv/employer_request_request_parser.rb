module Parsers::Xml::Cv
  class EmployerRequestRequestParser
    include HappyMapper
    register_namespace 'ridp', 'http://openhbx.org/api/terms/1.0'
    namespace 'ridp'
    tag 'request'

    element :request_name, String, tag: "request_name", :namespace => 'ridp'
    element :parameters, Parsers::Xml::Cv::EmployerRequestParameterParser::Type, tag: "parameter", :namespace => 'ridp'

    def to_hash
      {
          request_name: request_name,
          parameters: parameters.map(&:to_hash)
      }
    end
  end
end

