require 'java'

java_import 'com.amazonaws.codepipeline.jobworker.model.CurrentRevision'
java_import 'com.amazonaws.codepipeline.jobworker.model.FailureDetails'
java_import 'com.amazonaws.codepipeline.jobworker.model.FailureType'
java_import 'com.amazonaws.codepipeline.jobworker.model.ExecutionDetails'
java_import 'com.amazonaws.codepipeline.jobworker.model.WorkItem'
java_import 'com.amazonaws.codepipeline.jobworker.model.WorkResult'
java_import 'com.amazonaws.codepipeline.jobworker.JobProcessor'
java_import 'java.util.UUID'

require 'aws-sdk'
require 'cfn-nag'
require 'rubygems'
require 'zip'

class SampleCodePipelineJobProcessor
  include JobProcessor

  #
  # the heart of the matter.... do the work for the build step here
  # and return success or failure back to codepipeline,
  #
  # this sample makes a call out to the AWS API just to prove that the
  # gems specified in the pom.xml get wrapped up in the deployment unit
  # and that a require here can find them properly
  #
  def process(work_item)
    action_configuration_hash = work_item.getJobData.getActionConfiguration

    input_artifact = work_item.getJobData.getInputArtifacts
    artifact_bucket = input_artifact[0].s3BucketName
    object_key = input_artifact[0].s3ObjectKey

    codepipeline = Aws::CodePipeline::Client.new(region: 'us-east-1')
    s3 = Aws::S3::Client.new

    File.open('/var/tmp/input_artifact.zip', 'wb') do |file|
      resp = s3.get_object({ bucket: artifact_bucket, key: object_key }, target: file)
    end

    unzip('/var/tmp/input_artifact.zip', '/var/tmp/input_artifact')

    total_failure_count = audit(input_path: '/var/tmp/input_artifact/cfn')

    if total_failure_count == 0
      WorkResult.success work_item.getJobId,
                      ExecutionDetails.new('No violations!', UUID.randomUUID.toString, 100),
                      CurrentRevision.new('test revision', 'test change identifier')
    else
      WorkResult.failure work_item.getJobId,
                         FailureDetails.new(FailureType::JobFailed, 'Violations were detected!')
    end
  end

  private

  def unzip(zip, unzip_dir)
    Zip::File.open(zip) do |zip_file|
      zip_file.each do |f|
        f_path=File.join(unzip_dir, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path) unless File.exist?(f_path)
      end
    end
  end

  def cfn_nag
    config = CfnNagConfig.new
    CfnNag.new(config: config)
  end

  def audit(input_path:)
    aggregate_results = cfn_nag.audit_aggregate_across_files(input_path: input_path)

    File.open('/var/tmp/results.txt', 'w') do |file|
      file << cfn_nag.render_results(aggregate_results: aggregate_results,
                             output_format: 'txt')
    end

    aggregate_results.inject(0) do |total_failure_count, results|
      total_failure_count + results[:file_results][:failure_count]
    end
  end

end
