module Parsers::Xml::Cv
  class EmployerRequestParser
    include HappyMapper

    register_namespace 'ridp', 'http://openhbx.org/api/terms/1.0'
    namespace 'ridp'
    tag 'employer_request'

    element :header, Parsers::Xml::Cv::EmployerRequestHeaderParser::Type, tag: "header", :namespace => 'ridp'
    element :request, Parsers::Xml::Cv::EmployerRequestRequestParser::Type, tag: "request", :namespace => 'ridp'

    def to_hash
      {
          header: header.to_hash,
          request: request.to_hash
      }
    end
  end
end