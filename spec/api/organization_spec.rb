# -*- coding: utf-8 -*-
#
# Author:: Ho-Sheng Hsiao (<hosh@opscode.com>)
# Author:: Tyler Cloke (<tyler@getchef.com>)
# Copyright:: Copyright (c) 2013 Opscode, Inc.

require 'pedant/rspec/common'
require 'json'

describe "/organizations", :organizations do
  describe "GET /organizations" do
    let(:request_method) { :GET }
    let(:request_url)    { "#{platform.server}/organizations" }
    let(:requestor)      { superuser }

    let(:expected_response) { ok_response }

    should_respond_with 200
  end


  describe "GET /organizations/:id" do
    let(:request_method) { :GET }
    let(:request_url)    { "#{platform.server}/organizations/#{platform.test_org.name}" }
    let(:requestor)      { superuser }

    let(:expected_response) { ok_response }

    should_respond_with 200
  end

  describe "POST /organizations"  do
    let(:orgname) { "test-#{Time.now.to_i}-#{Process.pid}" }
    let(:request_body) do
      {
        full_name: "fullname-#{orgname}",
        name: orgname,
        org_type: "Business",
      }
    end

    after :each do
      delete("#{platform.server}/organizations/#{orgname}", superuser)
    end

    it "should respond with a valid newly created organization" do
      post("#{platform.server}/organizations", superuser, :payload => request_body).should look_like(:body => {
        "clientname" => "#{orgname}-validator"
      })
    end

    it "should respond with data containing a valid private key" do
      result = JSON.parse(post("#{platform.server}/organizations", superuser, :payload => request_body))
      /-----BEGIN RSA PRIVATE KEY-----/.should match(result["private_key"])
    end
  end

  ##########################
  # Internal account tests #
  ##########################

  describe "POST /internal-organizations", :'internal-account' do
    let(:orgname)      { "test-#{Time.now.to_i}-#{Process.pid}" }
    let(:request_body) do
      {
        full_name: "Pre-created",
        name: orgname,
        org_type: "Business",
      }
    end

    after :each do
      delete("#{platform.server}/organizations/#{orgname}", superuser)
    end

    context "when creating a new org" do
      it "should respond with a valid newly created organization" do
        authenticated_request(:POST, "#{platform.internal_account_url}/internal-organizations", superuser, :payload => request_body).should look_like(:body => {
          "clientname" => "#{orgname}-validator"
        })
      end
    end

    context "when attempting to create a new org and that org already exists" do
      it "should respond with a valid newly created organization" do
        # seed the org
        authenticated_request(:POST, "#{platform.internal_account_url}/internal-organizations", superuser, :payload => request_body)

        authenticated_request(:POST, "#{platform.internal_account_url}/internal-organizations", superuser, :payload => request_body).should look_like(:status => 409)
      end
    end

  end

  describe "PUT /internal-organizations", :'internal-account' do
    let(:orgname) { "test-#{Time.now.to_i}-#{Process.pid}" }
    let(:post_request_body) do
      {
        full_name: "Pre-created",
        name: orgname,
        org_type: "Business",
      }
    end

    before :each do
      authenticated_request(:POST, "#{platform.internal_account_url}/internal-organizations", superuser, :payload => post_request_body)
    end

    after :each do
      delete("#{platform.server}/organizations/#{orgname}", superuser)
    end

    context "when an org is updated to unassigned = true with a PUT" do
      let(:put_request_body) do
        {
          unassigned: true,
        }
      end

      it "should update the organization's unassigned field" do
        # since there is no way of actually getting the assigned field back from the API that I know of
        # best tests I can think of
        authenticated_request(:PUT, "#{platform.internal_account_url}/internal-organizations/#{orgname}", superuser, :payload => put_request_body).should look_like(:status => 200)

        get("#{platform.server}/organizations/ponyville", superuser).should look_like(:body => {
         "assigned_at "=> nil
        })
      end
    end

    # TODO: PUT only accepts unassigned: true, which I think is interesting behavior
    # for an API. If the only thing it does is set assigned to true, why not not have a
    # payload at all and maybe make the API more explicit like
    # PUT /internal-organizations/unassign/:id/
    context "when an org is updated to unassigned = false with a PUT" do
      let(:put_request_body) do
        {
          unassigned: false,
        }
      end

      it "should return an error" do
        authenticated_request(:PUT, "#{platform.internal_account_url}/internal-organizations/#{orgname}", superuser, :payload => put_request_body).should look_like(:body => {                                                                  "error" => "Cannot assign org #{orgname} - unassigned=true is only allowable operation",
        })
      end
    end
  end

end
