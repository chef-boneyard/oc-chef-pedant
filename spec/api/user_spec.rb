# -*- coding: utf-8 -*-
require 'pedant/rspec/common'

describe "users", :users do
  def self.ruby?
    Pedant::Config.ruby_users_endpoint?
  end

  def ruby_org_assoc?
    true
  end

  let(:public_key_regex) do
    # Because of a difference in the OpenSSL library between ruby 1.8.7
    # (actually 1.9.2) and 1.9.3, we have to accept multiple patterns here:
    /^-----BEGIN (RSA )?PUBLIC KEY-----/
  end

  let(:private_key_regex) do
    /^-----BEGIN (RSA )?PRIVATE KEY-----/
  end

  # Pedant has configurable test users.
  # Selects Pedant users that are marked as associated
  let(:default_pedant_user_names) { platform.users.select(&:associate).map(&:name).sort }
  let(:default_users_body)        { default_pedant_user_names.map { |user| {"user" => {"username" => user} } } }

  context "/organizations/<org>/users endpoint" do
    let(:request_url) { api_url("users") }

    context "GET /organizations/<org>/users" do
      let(:users_body) { default_users_body }

      context "admin user" do
        it "can get org users", :smoke do
          get(request_url, platform.admin_user).should look_like({
              :status => 200,
              :body_exact => users_body
            })
        end
      end

      context "default normal user" do
        it "can get org users", :smoke do
          get(request_url, platform.non_admin_user).should look_like({
              :status => 200,
              :body_exact => users_body
            })
        end
      end

      context "default client" do
        it "returns 403" do
          get(request_url, platform.non_admin_client).should look_like({
              :status => 403
            })
        end
      end

      context "outside user" do
        it "returns 403" do
          get(request_url, outside_user).should look_like({
              :status => 403
            })
        end
      end

      context "invalid user" do
        it "returns 401" do
          get(request_url, invalid_user).should look_like({
              :status => 401
            })
        end
      end
    end # context GET /organizations/<org>/users

    context "PUT /organizations/<org>/users" do
      context "admin user" do
        it "returns  404[ruby]/405[erlang]" do
          put(request_url, platform.admin_user).should look_like({
              :status => ruby_org_assoc? ? 404 : 405
            })
        end
      end
    end # context PUT /organizations/<org>/users

    context "POST /organizations/<org>/users" do
      context "admin user" do
        # A 405 here would be fine (and is no doubt coming with erlang)
        it "returns  404[ruby]/405[erlang]" do
          post(request_url, platform.admin_user).should look_like({
              :status => ruby_org_assoc? ? 404 : 405
            })
        end
      end
    end # context POST /organizations/<org>/users

    context "DELETE /organizations/<org>/users" do
      context "admin user" do
        # A 405 here would be fine (and is no doubt coming with erlang)
        it "returns  404[ruby]/405[erlang]" do
          delete(request_url, platform.admin_user).should look_like({
              :status => ruby_org_assoc? ? 404 : 405
            })
        end
      end
    end # context DELETE /organizations/<org>/users
  end # context /organizations/<org>/users endpoint

  context "/organizations/<org>/users/<name>" do
    let(:username) { platform.non_admin_user.name }
    let(:request_url) { api_url("users/#{username}") }

    context "GET /organizations/<org>/users/<name>" do
      let(:user_body) do
        {
          "first_name" => username,
          "last_name" => username,
          "display_name" => username,
          "email" => "#{username}@opscode.com",
          "username" => username,
          "public_key" => public_key_regex
        }
      end

      context "superuser" do
        it "can get user" do
          get(request_url, platform.superuser).should look_like({
              :status => 200,
              :body_exact => user_body
            })
        end
      end

      context "admin user" do
        it "can get user", :smoke do
          get(request_url, platform.admin_user).should look_like({
              :status => 200,
              :body_exact => user_body
            })
        end
      end

      context "default normal user" do
        it "can get self", :smoke do
          get(request_url, platform.non_admin_user).should look_like({
              :status => 200,
              :body_exact => user_body
            })
        end
      end

      context "default client" do
        it "returns 403" do
          get(request_url, platform.non_admin_client).should look_like({
              :status => 403
            })
        end
      end

      context "outside user" do
        it "returns 403" do
          get(request_url, outside_user).should look_like({
              :status => 403
            })
        end
      end

      context "invalid user" do
        it "returns 401" do
          get(request_url, invalid_user).should look_like({
              :status => 401
            })
        end
      end

      context "when requesting user that doesn't exist" do
        let(:username) { "bogus" }
        it "returns 404" do
          get(request_url, platform.admin_user).should look_like({
              :status => 404
            })
        end
      end
    end # context GET /organizations/<org>/users/<name>

    context "PUT /organizations/<org>/users/<name>" do
      context "admin user" do
        # A 405 here would be fine (and is no doubt coming with erlang)
        it "returns  404[ruby]/405[erlang]" do
          put(request_url, platform.admin_user).should look_like({
              :status => ruby_org_assoc? ? 404 : 405
            })
        end
      end
    end # context PUT /organizations/<org>/users/<name>

    context "POST /organizations/<org>/users/<name>" do
      context "admin user" do
        # A 405 here would be fine (and is no doubt coming with erlang)
        it "returns  404[ruby]/405[erlang]" do
          post(request_url, platform.admin_user).should look_like({
              :status => ruby_org_assoc? ? 404 : 405
            })
        end
      end
    end # context POST /organizations/<org>/users/<name>

    context "DELETE /organizations/<org>/users/<name>" do
      let(:username) { "test-#{Time.now.to_i}-#{Process.pid}" }
      let(:test_user) { platform.create_user(username) }

      before :each do
        platform.associate_user_with_org(org, test_user)
        platform.add_user_to_group(org, test_user, "users")
      end

      after :each do
        delete("#{platform.server}/users/#{username}", platform.superuser)
      end

      context "admin user" do
        it "can delete user", :smoke do
          delete(request_url, platform.admin_user).should look_like({
              :status => 200
            })
          get(api_url("users"), platform.admin_user).should look_like({
              :status => 200,
              :body_exact => default_users_body })
        end
      end

      context "non-admin user" do
        it "returns 403" do
          pending "actually returns 400" do # Wut?
            delete(request_url, platform.non_admin_user).should look_like({
                :status => 403
              })
            get(api_url("users"), platform.admin_user).should look_like({
                :status => 200,
                :body_exact => [
                  {"user" => {"username" => platform.admin_user.name}},
                  {"user" => {"username" => platform.non_admin_user.name}},
                  {"user" => {"username" => username}}
                ]})
          end
        end
      end

      context "default client" do
        it "returns 403" do
          pending "actually returns 400" do # Wut?
            delete(request_url, platform.non_admin_client).should look_like({
                :status => 403
              })
            get(api_url("users"), platform.admin_user).should look_like({
                :status => 200,
                :body_exact => [
                  {"user" => {"username" => platform.admin_user.name}},
                  {"user" => {"username" => platform.non_admin_user.name}},
                  {"user" => {"username" => username}}
                ]})
          end
        end
      end

      context "when user doesn't exist" do
        let(:request_url) { api_url("users/bogus") }
        it "returns 404" do
          delete(request_url, platform.non_admin_client).should look_like({
              :status => 404
            })
          get(api_url("users"), platform.admin_user).should look_like({
              :status => 200,
              :body_exact => default_users_body + [ {"user" => {"username" => username}} ]})
        end
      end
    end # context DELETE /organizations/<org>/users/<name>
  end # context /organizations/<org>/users/<name>
  context "/users endpoint" do
    let(:request_url) { "#{platform.server}/users" }

    context "GET /users" do
      let(:users_body) do
        {
          # There are other users, but these are ours, so they should always be
          # somewhere in the userspace soup.
          "pivotal" => "#{request_url}/pivotal",
          platform.bad_user.name => "#{request_url}/#{platform.bad_user.name}",
          platform.admin_user.name => "#{request_url}/#{platform.admin_user.name}",
          platform.non_admin_user.name => "#{request_url}/#{platform.non_admin_user.name}",
        }
      end
      let(:empty_users_body) do
        {}
      end
      let(:filtered_users_body) do
        {
          platform.non_admin_user.name => "#{request_url}/#{platform.non_admin_user.name}"
        }
      end

      context "superuser" do
        it "can get all users", :smoke do
          get(request_url, platform.superuser).should look_like({
              :status => 200,
              :body => users_body
            })
        end

        it "returns no users when filtering by non-existing email", :smoke do
          get("#{request_url}?email=somenonexistingemail@somewhere.com", platform.superuser).should look_like({
              :status => 200,
              :body_exact => empty_users_body
            })
        end

        it "returns a single user when filtering by that user's email address", :smoke do
          # Let's get a known user and mail address.
          response = get("#{request_url}/#{platform.non_admin_user.name}", platform.superuser)
          email = JSON.parse(response)["email"]
          get("#{request_url}?email=#{email}", platform.superuser).should look_like({
              :status => 200,
              :body_exact => filtered_users_body
            })
        end

        it "returns a verbose list of users upon request" do
          body = JSON.parse(get("#{request_url}?verbose=true", platform.superuser))
          [ platform.non_admin_user.name, platform.admin_user.name, platform.superuser.name ].each do |name|
            data = body[name]
            data.should_not be nil
            data.key?("first_name").should be true
            data.key?("last_name").should be true
            data.key?("email").should be true
          end
        end

      end

      context "admin user" do
        it "returns 403", :smoke do
          get(request_url, platform.admin_user).should look_like({
              :status => 403
            })
        end
      end

      context "default normal user" do
        it "returns 403" do
          get(request_url, platform.non_admin_user).should look_like({
              :status => 403
            })
        end
      end

      context "default client" do
        it "returns 401" do
          get(request_url, platform.non_admin_client).should look_like({
              :status => 401
            })
        end
      end

      context "outside user" do
        it "returns 403" do
          get(request_url, outside_user).should look_like({
              :status => 403
            })
        end
      end

      context "invalid user" do
        it "returns 401" do
          get(request_url, invalid_user).should look_like({
              :status => 401
            })
        end
      end
    end # context GET /users

    context "PUT /users" do
      context "admin user" do
        # A 405 here would be fine (and is no doubt coming with erlang)
        it "returns  404[ruby]/405[erlang]" do
          put(request_url, platform.admin_user).should look_like({
              :status => ruby? ? 404 : 405
            })
        end
      end
    end # context PUT /users

    context "POST /users" do
      let(:username) { "test-#{Time.now.to_i}-#{Process.pid}" }
      let(:user_url) { "#{request_url}/#{username}" }
      let(:request_body) do
        {
          "username" => username,
          "email" => "#{username}@opscode.com",
          "first_name" => username,
          "last_name" => username,
          "display_name" => username,
          "password" => "badger badger"
        }
      end

      let(:response_body) do
        {
          "uri" => "#{platform.server}/users/#{username}",
          "private_key" => private_key_regex
        }
      end

      let(:users_with_new_user) do
        {
          # There are other users, but these are ours, so they should always be
          # somewhere in the userspace soup:
          "pivotal" => "#{request_url}/pivotal",
          platform.bad_user.name => "#{request_url}/#{platform.bad_user.name}",
          platform.admin_user.name => "#{request_url}/#{platform.admin_user.name}",
          platform.non_admin_user.name => "#{request_url}/#{platform.non_admin_user.name}",
          # As should our test user:
          username => user_url
        }
      end

      after :each do
        # For the test with a space: we can't create it -- but also can't delete it,
        # ne?  No naked spaces allowed in URLs.
        if (username !~ / /)
          delete("#{platform.server}/users/#{username}", platform.superuser)
        end
      end

      context "superuser" do
        it "can create new user", :smoke do
          post(request_url, platform.superuser,
            :payload => request_body).should look_like({
              :status => 201,
              :body_exact => response_body
            })
          get(request_url, platform.superuser).should look_like({
              :status => 200,
              :body => users_with_new_user
            })
          get(user_url, platform.superuser).should look_like({
              :status => 200
            })
        end
      end

      context "admin user" do
        it "returns 403", :smoke do
          post(request_url, platform.admin_user,
            :payload => request_body).should look_like({
              :status => 403
            })
          get(user_url, platform.superuser).should look_like({
              :status => 404
            })
        end
      end

      context "creating users" do
        context "without password" do
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => username
            }
          end

          it "returns 400" do
            post(request_url, platform.superuser,
                 :payload => request_body).should look_like({
                   :status => 400
                 })
          end
        end

        context "without display_name" do
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "password" => "badger badger"
            }
          end

          it "returns 400" do
            post(request_url, platform.superuser,
                 :payload => request_body).should look_like({
                   :status => 400
                 })
          end
        end

        context "without first and last name" do
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "display_name" => username,
              "password" => "badger badger"
            }
          end

          it "can create new user" do
            post(request_url, platform.superuser,
              :payload => request_body).should look_like({
                :status => 201,
                :body_exact => response_body
              })
            get(request_url, platform.superuser).should look_like({
                :status => 200,
                :body => users_with_new_user
              })
          end
        end

        context "without email" do
          let(:request_body) do
            {
              "username" => username,
              "first_name" => username,
              "last_name" => username,
              "display_name" => username,
              "password" => "badger badger"
            }
          end

          it "returns 400" do
            post(request_url, platform.superuser,
                 :payload => request_body).should look_like({
                   :status => 400
                 })
          end
        end

        context "without username" do
          let(:request_body) do
            {
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => username,
              "password" => "badger badger"
            }
          end

          it "returns 400" do
            post(request_url, platform.superuser,
                 :payload => request_body).should look_like({
                   :status => 400
                 })
          end
        end

        context "with invalid email" do
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@foo @ bar ahhh it's eating my eyes",
              "first_name" => username,
              "last_name" => username,
              "display_name" => username,
              "password" => "badger badger"
            }
          end

          it "returns 400" do
            post(request_url, platform.superuser,
              :payload => request_body).should look_like({
                :status => 400
              })
          end
        end

        context "with spaces in names" do
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => "Yi Ling",
              "last_name" => "van Dijk",
              "display_name" => username,
              "password" => "badger badger"
            }
          end

          it "can create new user" do
            post(request_url, platform.superuser,
              :payload => request_body).should look_like({
                :status => 201,
                :body_exact => response_body
              })
            get(request_url, platform.superuser).should look_like({
                :status => 200,
                :body => users_with_new_user
              })
          end
        end

        context "with bogus field" do
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => username,
              "password" => "badger badger",
              "bogus" => "look at me"
            }
          end

          it "can create new user" do
            post(request_url, platform.superuser,
              :payload => request_body).should look_like({
                :status => 201,
                :body_exact => response_body
              })
            get(request_url, platform.superuser).should look_like({
                :status => 200,
                :body => users_with_new_user
              })
          end
        end

        context "with space in display_name" do
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => "some user",
              "password" => "badger badger"
            }
          end

          it "can create new user" do
            post(request_url, platform.superuser,
              :payload => request_body).should look_like({
                :status => 201,
                :body_exact => response_body
              })
            get(request_url, platform.superuser).should look_like({
                :status => 200,
                :body => users_with_new_user
              })
          end
        end

        context "with UTF-8 in display_name" do
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => "超人",
              "password" => "badger badger"
            }
          end

          it "can create new user" do
            post(request_url, platform.superuser,
              :payload => request_body).should look_like({
                :status => 201,
                :body_exact => response_body
              })
            get(request_url, platform.superuser).should look_like({
                :status => 200,
                :body => users_with_new_user
              })
          end
        end

        context "with UTF-8 in first/last name" do
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => "Guðrún",
              "last_name" => "Guðmundsdóttir",
              "display_name" => username,
              "password" => "badger badger"
            }
          end

          it "can create new user" do
            post(request_url, platform.superuser,
              :payload => request_body).should look_like({
                :status => 201,
                :body_exact => response_body
              })
            get(request_url, platform.superuser).should look_like({
                :status => 200,
                :body => users_with_new_user
              })
          end
        end

        context "with capitalized username" do
          let(:username) { "Test-#{Time.now.to_i}-#{Process.pid}" }
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => username,
              "password" => "badger badger"
            }
          end

          it "returns 400" do
            post(request_url, platform.superuser,
                 :payload => request_body).should look_like({
                   :status => 400
                 })
          end
        end

        context "with space in username" do
          let(:username) { "test #{Time.now.to_i}-#{Process.pid}" }
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => username,
              "password" => "badger badger"
            }
          end

          it "returns 400" do
            post(request_url, platform.superuser,
                 :payload => request_body).should look_like({
                   :status => 400
                 })
          end
        end

        context "when user already exists" do
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => username,
              "password" => "badger badger"
            }
          end

          it "returns 409" do
            post(request_url, platform.superuser,
              :payload => request_body).should look_like({
                :status => 201,
                :body_exact => response_body
              })
            get(request_url, platform.superuser).should look_like({
                :status => 200,
                :body => users_with_new_user
              })
            post(request_url, platform.superuser,
              :payload => request_body).should look_like({
                :status => 409
              })
          end
        end
      end # context creating users
    end # context POST /users

    context "DELETE /users" do
      context "admin user" do
        it "returns  404[ruby]/405[erlang]" do
          delete(request_url, platform.admin_user).should look_like({
              :status => ruby? ? 404 : 405
            })
        end
      end
    end # context DELETE /users
  end # context /users endpoint

  context "/users/<name> endpoint" do
    let(:username) { platform.non_admin_user.name }
    let(:request_url) { "#{platform.server}/users/#{username}" }

    context "GET /users/<name>" do
      let(:user_body) do
        {
          "first_name" => username,
          "last_name" => username,
          "display_name" => username,
          "email" => "#{username}@opscode.com",
          "username" => username,
          "public_key" => public_key_regex
        }
      end

      context "superuser" do
        it "can get user" do
          get(request_url, platform.superuser).should look_like({
              :status => 200,
              :body_exact => user_body
            })
        end
      end

      context "admin user" do
        it "can get user" do
          get(request_url, platform.admin_user).should look_like({
              :status => 200,
              :body_exact => user_body
            })
        end
      end

      context "default normal user" do
        it "can get self" do
          get(request_url, platform.non_admin_user).should look_like({
              :status => 200,
              :body_exact => user_body
            })
        end
      end

      context "default client" do
        it "returns 401" do
          get(request_url, platform.non_admin_client).should look_like({
              :status => 401
            })
        end
      end

      context "outside user" do
        it "returns 403" do
          get(request_url, outside_user).should look_like({
              :status => 403
            })
        end
      end

      context "invalid user" do
        it "returns 401" do
          get(request_url, invalid_user).should look_like({
              :status => 401
            })
        end
      end

      context "when user doesn't exist" do
        let(:username) { "bogus" }
        it "returns 404" do
          get(request_url, platform.superuser).should look_like({
              :status => 404
            })
        end
      end
    end # context GET /users/<name>

    context "PUT /users/<name>" do
      let(:username) { "test-#{Time.now.to_i}-#{Process.pid}" }
      let(:request_body) do
        {
          "username" => username,
          "email" => "#{username}@opscode.com",
          "first_name" => username,
          "last_name" => username,
          "display_name" => "new name",
          "password" => "badger badger"
        }
      end

      let(:modified_user) do
        {
          "username" => username,
          "email" => "#{username}@opscode.com",
          "first_name" => username,
          "last_name" => username,
          "display_name" => "new name",
          "public_key" => public_key_regex
        }
      end
      let(:input_public_key) do
        <<EOF
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA+h5g/r/qaFH6OdYOG0OO
2/WpLb9qik7SPFmcOvujqZzLO2yv4kXwuvncx/ADHdkobaoFn3FE84uzIVCoSeaj
xTMeuTcPr5y+wsVqCYMkwIJpPezbwcrErt14BvD9BPN0UDyOJZW43ZN4iIw5xW8y
lQKuZtTNsm7FoznG+WsmRryTM3OjOrtDYjN/JHwDfrZZtVu7pT8FYnnz0O8j2zEf
9NALhpS7oDCf+VSo6UUk/w5m4/LpouDxT2dKBwQOuA8pzXd5jHP6rYdbHkroOUqx
Iy391UeSCiPVHcAN82sYV7R2MnUYj6b9Fev+62FKrQ6v9QYZcyljh6hldmcbmABy
EQIDAQAB
-----END PUBLIC KEY-----
EOF
          end


      before :each do
        response = post("#{platform.server}/users", platform.superuser,
          :payload => {
            "username" => username,
            "email" => "#{username}@opscode.com",
            "first_name" => username,
            "last_name" => username,
            "display_name" => username,
            "password" => "badger badger"
          })
        response.should look_like({
            :status => 201,
            :body_exact => {
              "uri" => "#{platform.server}/users/#{username}",
              "private_key" => private_key_regex
            }})

        @original_private_key = JSON.parse(response.body)["private_key"]
      end

      after :each do
        delete("#{platform.server}/users/#{username}", platform.superuser)
        @original_private_key = nil
      end

      context "superuser" do
        it "can modify user", :smoke do
          put(request_url, platform.superuser,
            :payload => request_body).should look_like({
              :status => 200
            })
          get(request_url, platform.superuser).should look_like({
              :status => 200,
              :body_exact => modified_user
            })
        end
      end

      context "admin user" do
        it "returns 403", :smoke do
          put(request_url, platform.admin_user,
            :payload => request_body).should look_like({
              :status => 403
            })
        end
      end

      context "default client" do
        it "returns 401" do
          put(request_url, platform.non_admin_client,
            :payload => request_body).should look_like({
              :status => 401
            })
        end
      end

      context "when modifying non-existent user" do
        let(:request_url) { "#{platform.server}/users/bogus" }
        it "returns 404" do
          put(request_url, platform.superuser,
            :payload => request_body).should look_like({
              :status => 404
            })
        end
      end

      context "modifying users" do
        context "without password" do
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => "new name"
            }
          end

          it "can modify user" do
            put(request_url, platform.superuser,
              :payload => request_body).should look_like({
                :status => 200
              })
            get(request_url, platform.superuser).should look_like({
                :status => 200,
                :body_exact => modified_user
              })
          end
        end

        context "with bogus field" do
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => "new name",
              "password" => "badger badger",
              "bogus" => "not a badger"
            }
          end

          it "can modify user" do
            put(request_url, platform.superuser,
              :payload => request_body).should look_like({
                :status => 200
              })
            get(request_url, platform.superuser).should look_like({
                :status => 200,
                :body_exact => modified_user
              })
          end
        end

        context "without display_name" do
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "password" => "badger badger"
            }
          end

          it "returns 400" do
            put(request_url, platform.superuser,
              :payload => request_body).should look_like({
                :status => 400
              })
          end
        end

        context "without first and last name" do
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "display_name" => "new name",
              "password" => "badger badger"
            }
          end

          let(:modified_user) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "display_name" => "new name",
              "public_key" => public_key_regex
            }
          end

          it "can modify user" do
            put(request_url, platform.superuser,
              :payload => request_body).should look_like({
                :status => 200
              })
            get(request_url, platform.superuser).should look_like({
                :status => 200,
                :body => modified_user
              })
          end
        end

        context "without email" do
          let(:request_body) do
            {
              "username" => username,
              "first_name" => username,
              "last_name" => username,
              "display_name" => username,
              "password" => "badger badger"
            }
          end

          it "returns 400" do
            put(request_url, platform.superuser,
              :payload => request_body).should look_like({
                :status => 400
              })
          end
        end

        context "without username" do
          let(:request_body) do
            {
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => username,
              "password" => "badger badger"
            }
          end

          it "returns 400" do
            put(request_url, platform.superuser,
              :payload => request_body).should look_like({
                :status => 400
              })
          end
        end

        context "with invalid email" do
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@foo @ bar no go",
              "first_name" => username,
              "last_name" => username,
              "display_name" => username,
              "password" => "badger badger"
            }
          end

          it "returns 400" do
            put(request_url, platform.superuser,
              :payload => request_body).should look_like({
                :status => 400
              })
          end
        end

        context "with spaces in names" do
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => "Ren Kai",
              "last_name" => "de Boers",
              "display_name" => username,
              "password" => "badger badger"
            }
          end

          let(:modified_user) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => "Ren Kai",
              "last_name" => "de Boers",
              "display_name" => username,
              "public_key" => public_key_regex
            }
          end

          it "can modify user" do
            put(request_url, platform.superuser,
              :payload => request_body).should look_like({
                :status => 200
              })
            get(request_url, platform.superuser).should look_like({
                :status => 200,
                :body => modified_user
              })
          end
        end

        context "with space in display_name" do
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => "some user",
              "password" => "badger badger"
            }
          end

          let(:modified_user) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => "some user",
              "public_key" => public_key_regex
            }
          end

          it "can modify user" do
            put(request_url, platform.superuser,
              :payload => request_body).should look_like({
                :status => 200
              })
            get(request_url, platform.superuser).should look_like({
                :status => 200,
                :body => modified_user
              })
          end
        end

        context "with UTF-8 in display_name" do
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => "ギリギリ",
              "password" => "badger badger"
            }
          end

          let(:modified_user) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => "ギリギリ",
              "public_key" => public_key_regex
            }
          end

          it "can modify user" do
            put(request_url, platform.superuser,
              :payload => request_body).should look_like({
                :status => 200
              })
            get(request_url, platform.superuser).should look_like({
                :status => 200,
                :body => modified_user
              })
          end
        end

        context "with UTF-8 in first/last name" do
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => "Eliška",
              "last_name" => "Horáčková",
              "display_name" => username,
              "password" => "badger badger"
            }
          end

          let(:modified_user) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => "Eliška",
              "last_name" => "Horáčková",
              "display_name" => username,
              "public_key" => public_key_regex
            }
          end

          it "can modify user" do
            put(request_url, platform.superuser,
              :payload => request_body).should look_like({
                :status => 200
              })
            get(request_url, platform.superuser).should look_like({
                :status => 200,
                :body => modified_user
              })
          end
        end

        context "with new password provided" do
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => "new name",
              "password" => "bidgerbidger"
            }
          end
          it "changes the password" do
            put_response = put(request_url, platform.superuser, :payload => request_body)
            put_response.should look_like({ :status => 200 })

            response = post("#{platform.server}/verify_password", platform.superuser,
                            :payload => { 'user_id_to_verify' => username, 'password' => 'bidgerbidger' })
            JSON.parse(response.body)["password_is_correct"].should eq(true)

          end
        end

        context "with public key provided" do
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => "new name",
              "password" => "badger badger",
              "public_key" => input_public_key
            }
          end
          it "accepts the public key and subsequently responds with it" do
            put_response = put(request_url, platform.superuser, :payload => request_body)
            put_response.should look_like({
                                            :status => 200,
                                            :body=> {
                                              "uri" => request_url
                                            },
                                          })
            get_response = get(request_url, platform.superuser)
            new_public_key = JSON.parse(get_response.body)["public_key"]
            new_public_key.should eq(input_public_key)
          end
        end
        context "with private_key = true" do
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => "new name",
              "password" => "badger badger",
              "private_key" => true
            }
          end

          it "returns a new private key, changes the public key" do
            original_response = get(request_url, platform.superuser)
            original_public_key = JSON.parse(original_response.body)["public_key"]

            put_response = put(request_url, platform.superuser, :payload => request_body)
            put_response.should look_like({
                                            :status => 200,
                                            :body_exact => {
                                              "uri" => request_url,
                                              "private_key" => private_key_regex
                                            },
                                          })

            new_private_key = JSON.parse(put_response.body)["private_key"]
            new_private_key.should_not eq(@original_private_key)

            new_response = get(request_url, platform.superuser)
            new_public_key = JSON.parse(new_response.body)["public_key"]
            new_public_key.should_not eq(original_public_key)
          end
        end

        context "with private_key = true and a public_key" do
          let(:request_body) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => "new name",
              "password" => "badger badger",
              "private_key" => true,
              "public_key" => input_public_key
            }
          end

          it "returns a new private key, changes the public key" do
            original_response = get(request_url, platform.superuser)
            original_public_key = JSON.parse(original_response.body)["public_key"]

            put_response = put(request_url, platform.superuser, :payload => request_body)
            put_response.should look_like({
                                            :status => 200,
                                            :body_exact => {
                                              "uri" => request_url,
                                              "private_key" => private_key_regex
                                            },
                                          })

            new_private_key = JSON.parse(put_response.body)["private_key"]
            new_private_key.should_not eq(@original_private_key)

            new_response = get(request_url, platform.superuser)
            new_public_key = JSON.parse(new_response.body)["public_key"]

            new_public_key.should_not eq(input_public_key)
            new_public_key.should_not eq(original_public_key)
          end
        end
      end # context modifying users

      context "renaming users" do
        let(:new_name) { "test2-#{Time.now.to_i}-#{Process.pid}" }
        let(:new_request_url) { "#{platform.server}/users/#{new_name}" }

        context "changing username" do
          let(:request_body) do
            {
              "username" => new_name,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => username,
              "password" => "badger badger"
            }
          end

          let(:modified_user) do
            {
              "username" => new_name,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => username,
              "public_key" => public_key_regex
            }
          end

          after :each do
            delete("#{platform.server}/users/#{new_name}", platform.superuser)
          end

          context "and the username is valid" do
            # Ideally these would be discrete tests: can we put it and get the correct response?
            # But the top-level PUT /users/:id context causes us some problems with it's before :each
            # behavior of recreating users.
            it "updates the user to the new name and provides a new uri" do
              put(request_url, platform.superuser,
                :payload => request_body).should look_like({
                  :status => 201,
                  :body_exact => { "uri" => new_request_url },
                  :headers => [ "Location" => new_request_url ]
                })

              # it "makes the user unavailable at the old URI"
              get(request_url, platform.superuser).should look_like({
                  :status => 404
                })
              # it "makes the user available at the new URI"
              get(new_request_url, platform.superuser).should look_like({
                  :status => 200,
                  :body_exact => modified_user
                })
            end
          end
        end

        context "changing username with UTF-8" do
          let(:new_name) { "テスト-#{Time.now.to_i}-#{Process.pid}" }

          let(:request_body) do
            {
              "username" => new_name,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => username,
              "password" => "badger badger"
            }
          end

          it "returns 400" do
            put(request_url, platform.superuser,
              :payload => request_body).should look_like({
                :status => 400
              })
            # it "does not process any change to username" do
            get(request_url, platform.superuser).should look_like({
                :status => 200
              })
          end
        end

        context "changing username with spaces" do
          let(:new_name) { "test #{Time.now.to_i}-#{Process.pid}" }

          let(:request_body) do
            {
              "username" => new_name,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => username,
              "password" => "badger badger"
            }
          end

          it "returns 400" do
            put(request_url, platform.superuser, :payload => request_body).should look_like({
                :status => 400
              })
            # it "does not process any change to username" do
            get(request_url, platform.superuser).should look_like({
                :status => 200
              })
          end
        end

        context "changing username with capital letters" do
          let(:new_name) { "Test-#{Time.now.to_i}-#{Process.pid}" }

          let(:request_body) do
            {
              "username" => new_name,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => username,
              "password" => "badger badger"
            }
          end

          it "returns 400" do
            put(request_url, platform.superuser,
              :payload => request_body).should look_like({
                :status => 400
              })
            # it "does not process any change to username" do
            get(request_url, platform.superuser).should look_like({
                :status => 200
              })
          end
        end


        context "new name already exists" do
          let(:request_body) do
            {
              "username" => platform.non_admin_user.name,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => username,
              "password" => "badger badger"
            }
          end

          let(:unmodified_user) do
            {
              "username" => username,
              "email" => "#{username}@opscode.com",
              "first_name" => username,
              "last_name" => username,
              "display_name" => username,
              "public_key" => public_key_regex
            }
          end

          it "returns 409" do
              put(request_url, platform.superuser,
                :payload => request_body).should look_like({
                  :status => 409
                })
              get(request_url, platform.superuser).should look_like({
                  :status => 200,
                  :body_exact => unmodified_user
                })
          end
        end
      end # context renaming users
    end # context PUT /users/<name>

    context "POST /users/<name>" do
      context "admin user" do
        # A 405 here would be fine (and is no doubt coming with erlang)
        it "returns  404[ruby]/405[erlang]" do
          post(request_url, platform.admin_user).should look_like({
              :status => ruby? ? 404 : 405
            })
        end
      end
    end # context POST /users/<name>

    context "DELETE /users/<name>" do
      let(:username) { "test-#{Time.now.to_i}-#{Process.pid}" }

      before :each do
        post("#{platform.server}/users", platform.superuser,
          :payload => {
            "username" => username,
            "email" => "#{username}@opscode.com",
            "first_name" => username,
            "last_name" => username,
            "display_name" => username,
            "password" => "badger badger"
          }).should look_like({
            :status => 201,
            :body_exact => {
              "uri" => "#{platform.server}/users/#{username}",
              "private_key" => private_key_regex
            }})
      end

      after :each do
        delete("#{platform.server}/users/#{username}", platform.superuser)
      end

      context "superuser" do
        it "can delete user" do
          delete(request_url, platform.superuser).should look_like({
              :status => 200
            })
          # Similar to rename, the existing before :each interferese with making this into a separate test
          # because it recreates the user.
          # it "did delete the user"
          get(request_url, platform.superuser).should look_like({
              :status => 404
          })
        end

      end

      context "admin user" do
        it "returns 403" do
          delete(request_url, platform.admin_user).should look_like({
              :status => 403
            })
          # it "did not delete user" do
          get("#{platform.server}/users/#{username}",
            platform.superuser).should look_like({
              :status => 200
            })
        end
      end

      context "default client" do
        it "returns 401" do
          delete(request_url, platform.non_admin_client).should look_like({
              :status => 401
            })
          # it "did not delete user" do
          get("#{platform.server}/users/#{username}",
            platform.superuser).should look_like({
              :status => 200
            })
        end
      end

      context "when deleting a non-existent user" do
          let(:request_url) { "#{platform.server}/users/bogus" }
        it "returns 404" do
          delete(request_url, platform.superuser).should look_like({
              :status => 404
            })
        end
      end
    end # context DELETE /users/<name>
  end # context /users/<name> endpoint

  context "POST /verify_password" do
    let(:request_url) { "#{platform.server}/verify_password" }

    context "when the webui superuser is specified as the user" do
      let(:requestor) { superuser }

      let(:request_body) do
        {
          user_id_to_verify: superuser.name,
          password: "DOES_NOT_MATTER_FOR_TEST",
        }
      end

      it "should return Forbidden" do
        post(request_url, superuser, :payload => request_body).should look_like(
          :body => {
            "error" => "Password authentication as the superuser is prohibited."
          },
          :status => 403
        )
      end

    end # context when the webui superuser is specified as the user
  end # context POST /verify_password

  context "POST /authenticate_user" do
    let(:request_url) { "#{platform.server}/authenticate_user" }

    context "when the webui superuser is specified as the user" do
      let(:requestor) { superuser }

      let(:request_body) do
        {
          username: superuser.name,
          password: "DOES_NOT_MATTER_FOR_TEST",
        }
      end

      it "should return Forbidden" do
        post(request_url, superuser, :payload => request_body).should look_like(
          :body => {
            "error" => "Password authentication as the superuser is prohibited."
          },
          :status => 403
        )
      end

    end # context when the webui superuser is specified as the user
  end # context POST /authenticate_user
end # describe users
