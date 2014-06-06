# -*- coding: utf-8 -*-
#
# Author:: Tyler Cloke (<tyler@getchef.com>)
# Copyright:: Copyright (c) 2014 Chef, Inc.

describe 'system_recovery' do
  # TODO: do we wanna be able to test on actual LDAP user?
  # let (:username) {
  #   if Pedant::Config.ldap_testing
  #     Pedant::Config.ldap_account_name
  #   else
  #     platform.non_admin_user.name
  #   end
  # }
  # let (:password) {
  #   if Pedant::Config.ldap_testing
  #     Pedant::Config.ldap_account_password
  #   else
  #     'foobar'
  #   end
  # }

  let(:recoverable_user_id) { "#{Time.now.to_i}-#{Process.pid}" }

  let(:recoverable_username) { "recoverable_user-#{recoverable_user_id}" }

  let(:recoverable_user_create_body) do
    {
      display_name: recoverable_username,
      email: "#{recoverable_username}@getchef.com",
      password: "foobar",
      username: recoverable_username,
      external_auth_id: recoverable_user_id,
      recovery_authentication_enabled: true
    }
  end

  let (:recoverable_user_body) {
    { 'username' => recoverable_username,
      'password' => "foobar"
    }
  }

  let (:request_url) { "#{platform.server}/system_recovery" }

  # create a new recovery_authentication_enabled:true user
  before :each do
    post("#{platform.server}/users", superuser, :payload => recoverable_user_create_body)
  end

  # delete the user after test
  after :each do
    delete("#{platform.server}/users/#{recoverable_username}", superuser)
  end

  describe "POST /system_recovery" do

    context "when a user has recovery_authentication_enabled == true is requested" do

      context "when the superuser is the requestor" do

        it "should return the user body" do
          post(request_url, superuser, :payload => recoverable_user_body).should look_like(
            :body => {
              "display_name" => recoverable_username,
              "username" => recoverable_username,
              "email" => "#{recoverable_username}@getchef.com",
              "recovery_authentication_enabled" => true
            },
            :status => 200
          )
        end # should return the user body
      end # when the superuser is the requestor

      context "when the pasword passed is incorrect" do
        let (:wrong_pw_recoverable_user_body) {
          { 'username' => recoverable_username,
            'password' => "wrong_password"
          }
        }

        # TODO: opscode-account currently returns "Failed to authenticate: ".
        # It is executing "Failed to authenticate: #{$!}", so it is intending to
        # print the exception here, but we should have a more meanful message, see
        # the test for an example.
        it "should return 401 with an error message" do

          pending 'atrocious error message from opscode-account, see comment'

          post(request_url, superuser, :payload => wrong_pw_recoverable_user_body).should look_like(
            :body => {
              "error" => "Failed to authenticated as #{recoverable_username}. Password passed is incorrect."
            },
            :status => 401
          )
        end # should return 403 with an error message
      end # when the pasword passed is incorrect

      context "when a non-superuser is the requestor" do

        # TODO: the error strings returns the user in the body and not the
        # requestor user in opscode-account
        it "should return 403 with an error explaining non-superuser is not authorized" do

          pending 'opscode-account prints the user from the request body in error message and not requestor'

          post(request_url, platform.admin_user, :payload => recoverable_user_body).should look_like(
            :body => {
              "error" => "#{platform.admin_user.name} not authorized for verify_password"
            },
            :status => 403
          )
        end # should return 403 with an error explaining non-superuser is not authorized
      end # when a non-superuser is the requestor
    end # when a user has recovery_authentication_enabled == true is requested


    context "when a user has recovery_authentication_enabled != true is requested by the superuser" do

      let(:unrecoverable_user_id) { "#{Time.now.to_i}-#{Process.pid}" }

      let(:unrecoverable_username) { "unrecoverable_user-#{recoverable_user_id}" }

      let(:unrecoverable_user_create_body) do
        {
          display_name: unrecoverable_username,
          email: "#{unrecoverable_username}@getchef.com",
          password: "foobar",
          username: unrecoverable_username,
          external_auth_id: unrecoverable_user_id,
          recovery_authentication_enabled: false
        }
      end

      let (:unrecoverable_user_body) {
        { 'username' => unrecoverable_username,
          'password' => "foobar"
        }
      }

      # create a new recovery_authentication_enabled:false user
      before :each do
        post("#{platform.server}/users", superuser, :payload => unrecoverable_user_create_body)
      end

      # delete the user after test
      after :each do
        delete("#{platform.server}/users/#{unrecoverable_username}", superuser)
      end

      it "should return 403 with a relevant error message" do
        post(request_url, superuser, :payload => unrecoverable_user_body).should look_like(
          # TODO: this error isn't quite terrible enough to mark test as pending,
          # but it should be "Requestor" not "User"
          :body => {
            "error" => "User is not allowed to take this action"
          },
          :status => 403
        )
      end # should return 403 with a relevant error message
    end # when a user has recovery_authentication_enabled != true is requested by the superuser

    context "when a user that does not exist is requested by the superuser" do

      before :each do
        delete("#{platform.server}/users/#{recoverable_username}", superuser)
      end

      it "should return 404 with an error message" do
        post(request_url, superuser, :payload => recoverable_user_body).should look_like(
          :body => {
            "error" => "User is not found in the system"
          },
          :status => 404
        )
      end # should return 404 with an error message
    end # when a user that does not exist is requested by the superuser

    context "when the request is missing the username field" do

      let (:missing_username_body) {
        {
          'password' => "foobar"
        }
      }

      it "should return 400 with an error message" do
        post(request_url, superuser, :payload => missing_username_body).should look_like(
          :body => {
            "error" => "username and password are required"
          },
          :status => 400
        )
      end # should return 400 with an error message
    end # when the request is missing the username field

    context "when the request is missing the password field" do

      let (:missing_username_body) {
        {
          "username" => recoverable_username
        }
      }

      it "should return 400 with an error message" do
        post(request_url, superuser, :payload => missing_username_body).should look_like(
          :body => {
            "error" => "username and password are required"
          },
          :status => 400
        )
      end # should return 400 with an error message
    end # when the request is missing the password field

  end # POST /system_recovery
end # system_recovery
