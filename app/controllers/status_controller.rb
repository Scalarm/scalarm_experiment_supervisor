require 'scalarm/service_core/utils'

class StatusController < ApplicationController

  # TODO: check syntax of below apidoc
# =begin
#   @api {get} /status Service status
#   @apiName status#index
#   @apiGroup Status
#   @apiDescription Returns information about service status
#
#   @apiParam {String[]="database"} [tests] Additional tests to perform
#
#   @apiSuccess {String="ok","error"} status ok if everything is OK
#   @apiSuccess {String} [message] Additional status message, eg. if some tests failed
# =end
  def status
    tests = Scalarm::ServiceCore::Utils.parse_json_if_string(params[:tests])

    status = 'ok'
    message = ''

    unless tests.nil?
      failed_tests = tests.select do |t_name|
        test_method_name = "status_test_#{t_name}"
        not respond_to? test_method_name or not send(test_method_name)
      end

      unless failed_tests.empty?
        status = 'failed'
        message = "Failed tests: #{failed_tests.map {|tn| ERB::Util.h(tn)}.join(', ')}"
      end
    end

    http_status = (status == 'ok' ? :ok : :internal_server_error)

    respond_to do |format|
      format.html do
        render plain: message, status: http_status
      end
      format.json do
        render json: {status: status, message: message}, status: http_status
      end
    end
  end

  # --- Status tests ---

  def status_test_database
    Scalarm::Database::MongoActiveRecord.available?
  end

end
