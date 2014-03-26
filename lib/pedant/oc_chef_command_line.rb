module Pedant
  class CommandLine
    def oc_chef_options(opts) 
      tags = %w{object-identifiers}
      export_options(opts, tags)
    end
  end
end
