module Pedant
  class InternalAccount
    def oc_chef_options(opts)
      tags = %w{internal-account}
      export_options(opts, tags)
    end
  end
end
