GrapeSwaggerRails.options.url      = '/api/swagger_doc'
GrapeSwaggerRails.options.app_name = 'Octopub'
GrapeSwaggerRails.options.validator_url = nil

GrapeSwaggerRails.options.before_filter_proc = proc {
  GrapeSwaggerRails.options.app_url = request.protocol + request.host_with_port
}
