module Events
  class CensusEmployeesController < ::ApplicationController
    include Acapi::Amqp::Responder

    def resource(connection, delivery_info, properties, body)
      reply_to = properties.reply_to
      headers = properties.headers || {}
      ssn = headers.stringify_keys["ssn"]
      dob =  headers.stringify_keys["dob"]
      first_name = headers.stringify_keys["first_name"]
      last_name = headers.stringify_keys["last_name"]

      census_employees = find_census_employee({ssn:ssn, dob:dob, first_name:first_name })

      if !census_employees.nil?
        begin
          response_payload = render_to_string "events/employer_response/employer_response", :formats => ["xml"], :locals => { :census_employees => census_employees }
          reply_with(connection, reply_to, policy_id, "200", response_payload)
        rescue Exception => e
          reply_with(
            connection,
            reply_to,
            "500",
            JSON.dump({
               exception: e.inspect,
               backtrace: e.backtrace.inspect
            })
          )
        end
      else
        reply_with(connection, reply_to, "404", "")
      end
    end

    def reply_with(connection, reply_to, return_status, body, eligibility_event_kind = nil)

      headers = { 
              :return_status => return_status
      }

      if !eligibility_event_kind.blank?
        headers[:eligibility_event_kind] = eligibility_event_kind
      end

      with_response_exchange(connection) do |ex|
        ex.publish(
          body,
          {
            :routing_key => reply_to,
            :headers => headers
          }
        )
      end
    end

    def find_census_employee(options)
      CensusEmployee.where(encrypted_ssn: CensusMember.encrypt_ssn(ssn)).and(dob:option[:dob])
    end
  end
end
