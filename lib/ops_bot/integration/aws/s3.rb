# frozen_string_literal: true

class OpsBot::Integration::AWS::S3
  def initialize(bucket:)
    @bucket = bucket
  end

  def delete_directory(key:)
    resource
      .bucket(@bucket)
      .objects({ prefix: key })
      .batch_delete!
  end

  def delete_objects_older_than(time: 30.days)
    return if time.to_i.eql? 0

    resource
      .bucket(@bucket)
      .objects
      .filter { |obj| obj.last_modified < time.ago }
      .each &:delete
  end

  def file_exists?(key:)
    client.head_object(bucket: @bucket, key:)
    true
  rescue Aws::S3::Errors::NotFound
    false
  end

  def download_file(key:, file_path:)
    resource
      .bucket(@bucket)
      .object(key)
      .download_file(file_path)
  rescue Aws::S3::Errors::NotFound
    nil
  end

  def upload_file(key:, file_path:)
    resource
      .bucket(@bucket)
      .object(key)
      .upload_file(file_path)
  end

  def uri_for(key:)
    "s3://#{@bucket}/#{key}"
  end

  private

  def client
    @client ||= Aws::S3::Client.new
  end

  def resource
    @resource = Aws::S3::Resource.new(client:)
  end
end
