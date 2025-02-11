# AWS CodePipeline Job Worker
Read more about CodePipeline: http://aws.amazon.com/codepipeline/

## Build
### Dependencies
Install the following tools to build the AWS CodePipeline Job Worker:
- Java SE Development Kit 8
- Maven

## Start
Use the init.d script to start the AWS CodePipeline Job Worker polling for custom actions:
```bash
service aws-codepipeline-jobworker start
```

The script optionally takes the configuration class as a parameter. If you want to run the job worker for third party actions, you can use the following command:
```bash
service aws-codepipeline-jobworker start "com.amazonaws.codepipeline.jobworker.configuration.ThirdPartyJobWorkerConfiguration"
```

You can also specify your own configuration class. It only has to implement the `JobWorkerConfiguration` interface.

## Configuration
The job worker comes with two pre-defined configuration classes: `CustomActionJobWorkerConfiguration` and `ThirdPartyJobWorkerConfiguration`. Both inherit from the `DefaultJobWorkerConfiguration` to share most of the configuration settings.

You can configure the following settings:
```java
// Configure action type id the job worker polls for
public ActionTypeId getActionTypeId() {
    return new ActionTypeId(
        "Deploy",          // Action Type Category: Source, Build, Test, Deploy, Invoke
        "Custom",          // Action Type Owner: Custom or ThirdParty
        "MyCustomAction",  // Action Type Provider: Name of your action type
        "1"                // Action Type Version: e.g. "1"
    );
}

// How frequently the job worker polls for new jobs
private static final long POLL_INTERVAL_MS = 30000L; // e.g. every 30 seconds

// Maximum number of worker threads. Indicates how many jobs can be processed in parallel.
private static final int WORKER_THREADS = 10;
```

### AWS Region
* The AWS region for the custom job worker can be set with the `AWS_REGION` environment variable, and it will poll for jobs in this region.
* If the environment variable is not set, then the custom job worker will try to use the region of the EC2 instance on which it is running.
* You can also modify `getRegion()` method in `DefaultJobWorkerConfiguration.java`.
```java
    private static Region getRegion() {
        return Region.getRegion(Regions.US_EAST_1);
    }
```

## Deployment
The job worker comes with AWS CodeDeploy installation scripts. Set up your application and deployment group in AWS CodeDeploy and run the following command to deploy the agent:
```bash
# Replace with your Amazon S3 bucket name
AMAZON_S3_BUCKET=cfn-nag-jobworker-bucket<your-amazon-s3-bucket>
# Make sure that you set up your application and deployment group in AWS CodeDeploy
APPLICATION_NAME=AwsCodePipelineJobWorker
DEPLOYMENT_GROUP_NAME=Production

# Compile the code and create deployment bundle
ant release

# Create a tar archive from the build output
cd build/output
tar -cf ../AwsCodePipelineJobWorker.tar *

# Upload the deployment bundle to your Amazon S3 bucket.
aws s3 cp ../AwsCodePipelineJobWorker.tar s3://$AMAZON_S3_BUCKET/AwsCodePipelineJobWorker.tar

# Start the deployment using AWS CodeDeploy
aws deploy create-deployment --application-name $APPLICATION_NAME --deployment-group-name $DEPLOYMENT_GROUP_NAME --s3-location bucket=$AMAZON_S3_BUCKET,bundleType=tar,key=AwsCodePipelineJobWorker.tar
```

## Making a new custom action

1. Edit the src/main/ruby/jruby_code_pipeline_job_processor.rb to do what you want
2. Edit src/main/ruby/jruby_action_job_worker_configuration.rb to point to the processor and contain proper action identifiers
3. Update application-start.sh to refer to the proper configuration class
4. mvn install
5. Deploy target/AwsCodePipelineJobWorker-cp.tar through aforementioned instructions
6. Use AWS CLI to define custom action using src/main/resources/custom_action_defintion.json
7. Define CodePipeline pipeline and refer to action
8. To see worker in action, ssh into box where deployed and tail /var/log/aws-codepipeline-jobworker/*.log