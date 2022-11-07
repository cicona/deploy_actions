require 'pathname'
boot_script = File.join(
  Pathname.new('/').relative_path_from(Pathname.new("/#{File.dirname(__FILE__)}")),
  'config/boot.rb'
)
require_relative boot_script

iam_client = OpsBot::AWS::IAM.new

new_access_key = begin
  iam_client.rotate_access_key
rescue
  nil
end

if new_access_key.present?
  OpsBot::Context.env.access_key.serviced_repos.split(';').map(&:strip).each do |repo|
    github_client = OpsBot::GitHub.new(repo: repo)
    {
      'AWS_ACCESS_KEY_ID': new_access_key.access_key_id,
      'AWS_SECRET_ACCESS_KEY': new_access_key.secret_access_key
    }.each do |name, value|
      github_client.set_action_secret(
        name: name.to_s,
        value: value
      )
    end
  end
end

slack_client = OpsBot::Notification::Slack.new
slack_client.notify(
  template: 'rotate_keys-iam_github_action.json.erb',
  payload: {
    new_access_key: new_access_key
  }
)

exit(0)