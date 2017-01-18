module GrapeSwaggerRails
  class ApplicationController < ::ApplicationController

    before_action do
      if GrapeSwaggerRails.options.before_filter
        instance_exec(request, &GrapeSwaggerRails.options.before_filter)
      end
    end

    def index
    end

  end
end
