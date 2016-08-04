GrapeSwaggerRails.options.url      = '/api/swagger_doc'
GrapeSwaggerRails.options.app_name = 'Octopub'
GrapeSwaggerRails.options.validator_url = nil

GrapeSwaggerRails.options.api_key_name = 'Authorization'
GrapeSwaggerRails.options.api_key_type = 'header'

GrapeSwaggerRails.options.before_filter_proc = proc {
  GrapeSwaggerRails.options.app_url = request.protocol + request.host_with_port
}
