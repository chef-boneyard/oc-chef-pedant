# oc-chef-pedant

**Internal Repo**

This is the pedant test suite for Opscode Private Chef.

## Running the Tests in Development

The easiest way to run tests when hacking on either private chef
components or this test suite itself is to load this project into dev VM
and use `private-chef-ctl test`. If you can't do that for whatever
reason, you can run `bin/oc-chef-pedant -c CONFIG`. See
[multitenant_config.rb](multitenant_config.rb) for an example. Be sure
to correctly configure pedant for Ruby/Erlang as appropriate for your
test system.

When running oc-chef-pedant via `private-chef-ctl test`, pedant uses
configuration in `/var/opt/opscode/oc-chef-pedant/etc/pedant_config.rb`.
HTTP request data is logged to
`/var/log/opscode/oc-chef-pedant/http-traffic.log`.

When running tests manually, logging (and lots of other options) are
configured by command line switches. Run `bin/oc-chef-pedant -h` to list
them.

## Shared Functionality

Where functionality in OPC is shared/identical to that in Open Source
Chef Server, this test suite uses tests from
[chef-pedant](https://github.com/opscode/chef-pedant). By default, dev
VM is configured to mount your local chef-pedant checkout into the VM
when loading `oc-chef-pedant`. See the [dev VM config](https://github.com/opscode/opscode-dev-vm/blob/master/config/projects.json)
for details.

## Running Non-default Tests

There are some tests that only make sense to run in certain environments or that don't make sense to run by default.

#### LDAP Testing

For testing against LDAP, please update the entries in multitenant_config.rb. Set `ldap_testing` to true,
and fill in `ldap_account_name` and `ldap_account_password` with your AD credentials on your test server.

Additionally, set the following in your private-chef.rb file, run `private-chef-ctl reconfigure`,
and change out the <abstracted> bits since those don't need to be made public (no password for you,
and if you need it, you should be able to get the IP):

```
ldap['base_dn'] = 'dc=opscodecorp,dc=com'
ldap['bind_dn'] = 'CN=<full name>,OU=Employees,OU=Domain users,DC=opscodecorp,DC=com'
ldap['bind_password'] = '<same password as above>'
ldap['host'] = '<host IP address>'
```

This is good enough for quick ad-hoc testing, it will authenticate against my
username/password in the tests, but more robust LDAP testing is desirable in
the future.

#### Account Tests That Talk Via Internal Ports

The opscode-account endpoint for internal org creation and updating (```/internal-organizations```) communicates via the internal account port. That endpoint is not exposed via the external-lb. Therefore, they will fail when kicking off the tests from a point external to the lb (say, developer's laptop hitting hosted for pedant). However, they are useful in validating that these endpoint are still functioning, so if you are running pedant somewhere with access to the internal-lb, simply run

```private-chef-ctl test --all``` or ```private-chef-ctl test --only-internal-orgs```

to execute these tests.

If you want to run all the tests without the internal organization tests run

```private-chef-ctl test --all --exclude-internal-orgs```
