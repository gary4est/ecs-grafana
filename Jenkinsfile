//Jenkinsfile (Declarative Pipeline)

//AWS Regions (move to readYaml to support list instead of properties file)
AWS_REGIONS = [ 'us-west-2' ]

pipeline {

    agent {
        node {
            label 'jenkins2agent'
            customWorkspace "${env.HOME}/workspace/${env.JOB_NAME}/${env.BUILD_NUMBER}"
        }
    }

    options{
        buildDiscarder(logRotator(numToKeepStr: '30'))
        disableConcurrentBuilds()
        skipStagesAfterUnstable()
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
    }

    stages {
        stage('Initialize Environment') {
            environment {
                PROPS_FILE = 'jenkins.properties'
            }
            steps {
                script {
                    //load properties file
                    loadProperties()

                    slackSend channel: SLACK_CHANNEL,
                        message: """
                            |*----------- Start Build Pipeline ------------*
                        """.stripMargin()
                    }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh """ 
                    {
                    echo "----------------------------------------------------------------------"
                    echo "INFO: starting ${env.JOB_BASE_NAME} build"
                    echo "----------------------------------------------------------------------"
                    } 2> /dev/null
                    """

                    //checkout git repo
                    checkout scm

                    //get app version & set env variable
                    def gitCommit = sh(returnStdout: true, script: 'git rev-parse --short=7 HEAD').trim()
                    def grafanaVer = sh(returnStdout: true, script: "grep grafana Dockerfile | awk -F ':' '{print \$2}'").trim()

                    sh """
                    {
                        echo "----------------------------------------------------------------------"
                        echo "INFO: Building Grafana Version: ${grafanaVer} Commit ID: ${gitCommit}"
                        echo "----------------------------------------------------------------------"
                    } 2> /dev/null
                    """

                    APP_VER = grafanaVer.replace("/n","")
                    APP_VER = grafanaVer.replace("/n","")
                    env.APP_VER = APP_VER
                    COMMIT_ID = gitCommit.replace("/n","")
                    env.COMMIT_ID = COMMIT_ID

                    //get gitAuthor
                    def gitAuthor = sh(returnStdout: true, script: "git --no-pager show -s --format='%an' ${COMMIT_ID}").trim()
                    GIT_AUTHOR = gitAuthor.replace("/n","")
                    env.GIT_AUTHOR = GIT_AUTHOR

                    //notify start of pipeline
                    notifyPipelineStarted()


                    //build docker image
                    def image = docker.build("${APP_ECR}:${gitCommit}")

                    //Get Docker Image ID
                    def dockerImageId = sh(returnStdout: true, script: "docker images | grep -m 1 ${gitCommit} | awk '{print \$3}'").trim()

                    sh """#!/bin/bash
                    {
                        echo "----------------------------------------------------------------------"
                        echo "INFO: docker imageID: ${dockerImageId}"
                        echo "----------------------------------------------------------------------"
                    } 2> /dev/null
                    """

                    DOCKER_IMAGE_ID = dockerImageId.replace("/n","")
                    env.DOCKER_IMAGE_ID = DOCKER_IMAGE_ID
                }
            }
        }

        stage('Tag & Push Image to Repo') {
            /* Single environment, keep disabled for now.
            when {
                //Only push image to ECR if on master branch (merge to master)
                branch 'master'
            }*/
            steps {
                script {
                    //Call push_images method to loop by REGIONS and push to ECR
                    def push_images = push_image_to_ecr(AWS_REGIONS)
                }
            }
        }

        stage('Clean Up Images') {
            steps {
                script {
                    //clean up docker images
                    sh """
                        {
                            echo "----------------------------------------------------------------------"
                            echo "INFO: Clean up docker image ${env.DOCKER_IMAGE_ID}"
                            echo "----------------------------------------------------------------------"
                        } 2> /dev/null

                        docker rmi -f ${env.DOCKER_IMAGE_ID}
                        docker images
                    """
                }
            }
        }

        stage('Deploy to Grafana') {
            //Only deploy when on master branch (merge to master)
            when {
                branch 'master'
            }
            steps {
                //Deploy Docker Image to Dev
                sh """
                {
                    echo "----------------------------------------------------------------------"
                    echo "INFO: Deploy Grafana to AWS ECS"
                    echo "----------------------------------------------------------------------"
                } 2> /dev/null
                """

                //Call Deploy Job
                build job: "../ecs-grafana-deploy/master", parameters: [
                    string(name: 'ENVIRONMENT', value: 'management'),
                    string(name: 'STACKER_BRANCH', value: 'master'),
                    string(name: 'COMMIT_ID', value: "${env.COMMIT_ID}")
                ]
            }
        }
    }

    post {
        success {
            slackSend channel: SLACK_CHANNEL,
                      color: 'good',
                      message: """
                        |*Pipeline Suceeded*
                        |console output: <${env.BUILD_URL}console| console logs>
                        |
                        |*----------- End Pipeline ------------*
                      """.stripMargin()
        }

        failure {
            slackSend channel: SLACK_CHANNEL,
                      color: 'danger',
                      message: """
                        |Pipeline Failure: *<${env.JOB_URL}|${env.JOB_BASE_NAME.capitalize()}>*
                        |console output: <${env.BUILD_URL}console| console logs>
                        |
                        |*----------- ERROR Pipeline ------------*
                      """.stripMargin()
        }
        cleanup {
            echo "Clean up Workspace"
            deleteDir() /* clean up our workspace */
        }
    }
}

// Method to push images to ECR
//NonCPS
def push_image_to_ecr(list) {
    for (region in list) {

        ecr_registry_url = "${AWS_ACCOUNT}.dkr.ecr.${region}.amazonaws.com/${APP_ECR}"
        sh """
        {
            echo "-----------------------------------------------------------------------------------------"
            echo "INFO: pushing Docker Image ${env.DOCKER_IMAGE_ID} to ${ecr_registry_url}:${env.COMMIT_ID}"
            echo "-----------------------------------------------------------------------------------------"
        } 2> /dev/null
        """

        //Login to ECR
        sh """

        eval \$(aws ecr get-login --no-include-email --region ${region})

        docker tag ${env.DOCKER_IMAGE_ID} ${ecr_registry_url}:${env.COMMIT_ID}
        docker tag ${env.DOCKER_IMAGE_ID} ${ecr_registry_url}:${env.APP_VER}
        docker tag ${env.DOCKER_IMAGE_ID} ${ecr_registry_url}:latest

        docker push ${ecr_registry_url}

        {
            echo "-----------------------------------------------------------------------------------------"
            echo "INFO: pushed grafana build to ${ecr_registry_url}:${env.COMMIT_ID}"
            echo "-----------------------------------------------------------------------------------------"
        } 2> /dev/null
        """

        //notify Image pushed
        notifyImagePushed(ecr_registry_url)
    }

    sh "docker images"

    //notify Build successful
    notifyBuildSuccessful()
} //pipeline

//loadProperites from PROPS_FILE
def loadProperties() {
    sh """
    {
        echo "-----------------------------------------------------------------------------------------"
        echo "INFO: load config file ${PROPS_FILE}"
        echo "-----------------------------------------------------------------------------------------"
    } 2> /dev/null
    """
    def props = readProperties  file:"${PROPS_FILE}"
    APP_ECR = props['APP_ECR']
    GITHUB_URL = props['GITHUB_URL']
    SLACK_CHANNEL = props['SLACK_CHANNEL']
    AWS_ACCOUNT = props['AWS_ACCOUNT']
}

//Notifications
//Pipeline Started
def notifyPipelineStarted() {
    slackSend channel: SLACK_CHANNEL,
                color: "#439FE0",
                message: """
                  |*Pipeline Started*
                  |Build Started: *<${env.JOB_URL}|${env.JOB_BASE_NAME.capitalize()}>* for Grafana
                  |branch: <${GITHUB_URL}/pull${env.GIT_BRANCH.replace('origin/', '')}|${env.GIT_BRANCH.replace('origin/', '')}>
                  |build number: <${env.BUILD_URL}/console|${env.BUILD_NUMBER}>
                  |change author: ${env.GIT_AUTHOR}
                """.stripMargin()
}

//Build successfull
def notifyBuildSuccessful() {
    slackSend channel: SLACK_CHANNEL,
                color: 'good',
                message: """
                  |Build Success: *<${env.JOB_URL}|${env.JOB_BASE_NAME.capitalize()}>*
                  |build number: <${env.BUILD_URL}|${env.BUILD_NUMBER}>
                  |build time: ${currentBuild.durationString.replace(' and counting', '')}
                  |git commit_ID: *<${GITHUB_URL}/commit/${env.COMMIT_ID}|${env.COMMIT_ID}>*
                """.stripMargin()
}

//Deploy Started
def notifyDeployStarted() {
    slackSend channel: SLACK_CHANNEL,
                color: "#439FE0",
                message: """
                  |*Deploy Started* 
                  |Deploy Image: <${APP_URL}:8443/public/health|${env.COMMIT_ID}> 
                """.stripMargin()
}

//Image Pushed to ECR
def notifyImagePushed(ecr_repo) {
    slackSend channel: SLACK_CHANNEL,
                color: "#439FE0",
                message: """
                  |Pushed Docker Image: ${env.COMMIT_ID} to ${ecr_repo} ECR Repo
                """.stripMargin()
}
