class OpsBot::Notification::Slack < OpsBot::Notification::Base
  def initialize
    @channel_ids = begin
      client.auth_test
      OpsBot::Context.env.slack.channel_ids
    rescue
      $logger.error('Unable to initialize Slack client, skipping notification...')
      nil
    end
  end

  def notify(template:, payload: {})
    return if @channel_ids.blank?

    client.chat_postMessage(
      channel: @channel_ids,
      blocks: self.render(
        view_file: template,
        instance: self,
        payload: payload
      )
    )
  end

  private

    def client
      @client ||= ::Slack::Web::Client.new
    end
end
