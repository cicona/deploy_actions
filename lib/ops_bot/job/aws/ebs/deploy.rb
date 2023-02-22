class OpsBot::Job::AWS::EBS::Deploy < OpsBot::Job::Base
  def self.perform
    ebs_client = OpsBot::Integration::AWS::EBS.new
    ebs_version_label = OpsBot::Context.utils.build.version

    if ebs_client.version_exists?
      $logger.info("Existing application version found on EBS: #{ebs_version_label}, skipping version creation...")
    else
      ebs_client.create_version

      if ebs_client.version_exists?
        $logger.info("Created new EBS application version: #{ebs_version_label}")
      else
        $logger.error('Version creation failed. Check logs for errors.')
        return false
      end
    end

    ebs_client.deploy_version

    if OpsBot::Context.utils.workflow.is_production?
      slack_client = OpsBot::Notification::Slack.new
      slack_client.notify(template: 'aws-ebs-deploy.json.erb')
    end

    true
  end
end
