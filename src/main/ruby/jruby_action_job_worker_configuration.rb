require 'java'
java_import 'com.amazonaws.codepipeline.jobworker.JobService'
java_import 'com.amazonaws.codepipeline.jobworker.model.ActionTypeId'
java_import 'com.amazonaws.codepipeline.jobworker.plugin.customaction.CustomActionJobService'
java_import 'com.amazonaws.codepipeline.jobworker.configuration.DefaultJobWorkerConfiguration'

class SampleCustomJRubyActionJobWorkerConfiguration < DefaultJobWorkerConfiguration

  #
  # this should line up with resources/custom_action-definition.json
  # if this doesn't agree, the worker polling codepipeline will never think it has
  # work items to process
  #
  def getActionTypeId
    ActionTypeId.new 'Build',   # category
                     'Custom',  # third party or custom
                     'cfn-nag',   # provider
                     '3'        # version
  end

  def jobService
    CustomActionJobService.new codePipelineClient, getActionTypeId
  end

  def jobProcessor
    SampleCodePipelineJobProcessor.new
  end
end
