require 'java'

java_import 'com.amazonaws.codepipeline.jobworker.model.CurrentRevision'
java_import 'com.amazonaws.codepipeline.jobworker.model.ExecutionDetails'
java_import 'com.amazonaws.codepipeline.jobworker.model.WorkItem'
java_import 'com.amazonaws.codepipeline.jobworker.model.WorkResult'
java_import 'com.amazonaws.codepipeline.jobworker.JobProcessor'
java_import 'java.util.UUID'

require 'aws-sdk'
require 'cfn-nag'

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
    puts '========'
    puts "Action Configuration Hash: "
    puts action_configuration_hash
    puts '============'

    codepipeline = Aws::CodePipeline::Client.new(region: 'us-east-1')

    File.open('/var/tmp/cp_operation_names', 'w') { |file| file.write codepipeline.operation_names.to_s }

    WorkResult.success work_item.getJobId,
                       ExecutionDetails.new('test summary', UUID.randomUUID.toString, 100),
                       CurrentRevision.new('test revision', 'test change identifier')
  end
end
