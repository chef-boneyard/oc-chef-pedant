require "pedant/rspec/data_bag_util"
require "pedant/rspec/node_util"
require "pedant/rspec/search_util"
require "pedant/rspec/chef_data"

describe "Search API endpoint", :search do
  include Pedant::RSpec::DataBagUtil
  include Pedant::RSpec::EnvironmentUtil
  include Pedant::RSpec::NodeUtil
  include Pedant::RSpec::RoleUtil
  include Pedant::RSpec::SearchUtil

  include Pedant::RSpec::ChefData

  # TODO: until we rename requestors
  shared(:admin_requestor){admin_user}
  shared(:requestor){admin_requestor}

  context "/search/<data_bag>" do
    let(:request_url){api_url("/search/#{data_bag_name}")}

    context "using GET" do
      let(:request_method){:GET}

      context "an existing data bag" do
        let(:data_bag_items){[
          new_data_bag_item("foo"),
          new_data_bag_item("bar"),
        ]}
        let(:requestor) {normal_user}
        include_context "with testing data bag"
        include_context "with testing data bag items" do
          let(:items){data_bag_items}
        end

        it "should return no results to an unauthorized user" do
          restrict_permissions_to "/data/#{data_bag_name}",
                                  normal_user => [],
                                  admin_user => ["read", "delete"]

          with_search_polling do
            r = get(api_url("/search/#{data_bag_name}?q=id:*"), normal_user)
            parse(r)["rows"].should eq([])
          end
        end
      end
    end
  end

  %w{ environment node role }.each do |type|
    context "/search/#{type}" do
      let(:request_url){api_url("/search/#{type}")}
      setup_multiple_objects type.to_sym

      context "using GET" do
        let(:request_method){:GET}

        it "should return filtered results when ACLs exist" do
          restrict_permissions_to "/#{type}s/#{base_object_name}_3",
                                  normal_user => ["delete"]

          # A little bit of confirmation that the ACL has applied correctly
          n = get(api_url("/#{type}s/#{base_object_name}_3"), normal_user)
          n.should look_like({:status => 403})

          with_search_polling do
            r = get("#{request_url}/?q=name:*", normal_user)
            parse(r)["rows"].any? {|row| row["name"] == "#{base_object_name}_3"}.should be false
          end
        end

      end

      context "using POST" do
        let(:request_method){:POST}

        it "should return filtered results when ACLs exist" do
          restrict_permissions_to "/#{type}s/#{base_object_name}_3",
                                  normal_user => ["delete"]

          payload = { "name" => ["name"] }
          with_search_polling do
            r = post("#{request_url}?q=name:*", normal_user, {payload: payload})
            parse(r)["rows"].any? {|row| row["data"]["name"] == "#{base_object_name}_3"}.should be false
          end
        end
      end
    end
  end
end
