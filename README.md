# CI/CD with React, Docker, TravisCI, Github Actions and Netlify

This project is a simple React app that can be built locally with Docker and deployed to Netlify or AWS using TravisCI or Github Actions.

The inspiration for the workflos in this project came from Stephen Grider's [Docker and Kubernetes: The Complete Guide](https://www.udemy.com/course/docker-and-kubernetes-the-complete-guide/) course on Udemy. This is a great course for learning Docker and Kubernetes. I have taken his examples of deploying a React app to AWS with TravisCI and modified them to work with Netlify and GitHub Actions. I strongly encourage anyone interested in this topic to take his course.

## Table of Contents

- [CI/CD with React, Docker, TravisCI, Github Actions and Netlify](#cicd-with-react-docker-travisci-github-actions-and-netlify)
  - [Table of Contents](#table-of-contents)
  - [Prerequisites](#prerequisites)
  - [Notes about the Project](#notes-about-the-project)
  - [Notes about the CI/CD Methods](#notes-about-the-cicd-methods)
- [Fork This Repository and Pull It Locally](#fork-this-repository-and-pull-it-locally)
  - [Running the App with Docker](#running-the-app-with-docker)
  - [Running the Tests with Docker](#running-the-tests-with-docker)
  - [What about Dockerfile and docker-compose.yaml?](#what-about-dockerfile-and-docker-composeyaml)
- [CI/CD with GitHub Actions to Netlify](#cicd-with-github-actions-to-netlify)
  - [What is Netlify?](#what-is-netlify)
  - [Connecting Netlify to GitHub](#connecting-netlify-to-github)
  - [Running Tests with Netlify Build](#running-tests-with-netlify-build)
  - [Using GitHub Actions to Run Tests and Deploy to Netlify](#using-github-actions-to-run-tests-and-deploy-to-netlify)
- [CI/CD with TravisCI to AWS Elastic Beanstalk](#cicd-with-travisci-to-aws-elastic-beanstalk)
  - [What is TravisCI?](#what-is-travisci)
  - [Connecting TravisCI to GitHub](#connecting-travisci-to-github)
  - [Creating a TravisCI Workflow](#creating-a-travisci-workflow)
  - [Deploying to AWS Elastic Beanstalk for TravisCI](#deploying-to-aws-elastic-beanstalk-for-travisci)
    - [Creating Elastic Beanstock in AWS for TravisCI](#creating-elastic-beanstock-in-aws-for-travisci)
    - [In TravisCI](#in-travisci)
    - [In travis.yml](#in-travisyml)
- [CI/CD with GitHub Actions to AWS Elastic Beanstalk](#cicd-with-github-actions-to-aws-elastic-beanstalk)
  - [What is GitHub Actions?](#what-is-github-actions)
  - [Creating a Github Actions Workflow](#creating-a-github-actions-workflow)
  - [Deploying to AWS Elastic Beanstalk for GitHub Actions](#deploying-to-aws-elastic-beanstalk-for-github-actions)
    - [Creating Elastic Beanstock in AWS for GitHub Actions](#creating-elastic-beanstock-in-aws-for-github-actions)
    - [In GitHub](#in-github-actions)
    - [In ci.yml](#in-ciyml)

## Prerequisites

To follow this tutorial, you need to have the following:

- Docker installed locally
- A Github account (to push this code to and connect to TravisCI and Netlify, to run GitHub Actions)
- A TravisCI account (to run the CI/CD pipeline and deploy to AWS)
- A Netlify account (to deploy the app)
- An AWS account (to create an Elastic Beanstalk instance to deploy from TravisCI and GitHub Actions)

## Notes about the Project

The `Dockerfile` and `docker-compose.yaml` files are used for production. They are not used for development. The `Dockerfile.dev` and `docker-compose-dev.yaml` files are used for development - as you saw in the above steps.

**Notes:**

- If you get an error about the port being in use, you can run `docker-compose -f docker-compose-dev.yaml down` to stop the containers. Or run `docker stop $(docker ps -aq) && docker rm $(docker ps -aq)` to stop and remove all containers.
- The `--build` flag is only needed the first time you run the command.

## Notes about the CI/CD Methods

Everything in this tutorial is free EXCEPT:

- AWS Elastic Beanstalk can be free for new users, otherwise, it will cost money. Make sure you tear down the Elastic Beanstalk instance when you are done.
- TravisCI offers a trial period for new users. After the trial period, you will have to pay for the service. Make sure you tear down the TravisCI pipelines when you are done.

# Fork This Repository and Pull It Locally

To use this repository for any of the CI/CD methods we discussed, you can fork it to your GitHub account. Then clone it to your local machine.

```
git clone https://github.com/YOUR-USERNAME/ci-cd-webgeeks-feb-2023
```

You can see full instructions on how to do this [here](https://docs.github.com/en/get-started/quickstart/fork-a-repo).

Alternatively, you could clone this repository directly to your local machine. However, you will not be able to push your changes to GitHub unless you update the remote url.

## Running the App with Docker

The Dockerfile.dev looks something like this:

```
# Specify a base image
FROM node:18.13.0-alpine

# Set working directory to user app folder
WORKDIR '/app'

# Copy package.json and install depenendencies
COPY package.json .
RUN npm install

# Copy all the other files
COPY ./ ./

# Default command
CMD ["npm", "start"]
```

It is based on the `node:18.13.0-alpine` image. It copies the `package.json` file and installs the dependencies. It then copies all the other files and runs the default command `npm start`.

To run this Dockerfile, make sure you have Docker installed.

To build and run the app with Docker run the following commands:

```
docker build -f Dockerfile.dev -t simple-react .
docker run -p 3000:3000 simple-react
```

We could add volume mapping so that we don't have to rebuild the image every time we make a change to the code. To do this, we can add the following to the `docker run` command:

```
-v /app/node_modules -v $(pwd):/app
```

## Running the Tests with Docker

While the container is running, you can get the container ID using `docker ps`. To run the test, run the following command:

```
docker exec -it <container_id> npm run test
```

The `exec` command allows you to run a command inside a running container. The `-it` flag allows you to run the command interactively. The `npm run test` command runs the tests.

You can alternatively run tests with Docker using the following command even if the container is not running.

```
docker run simple-react npm run test
```

Here `npm run test` is the command that is run inside the container instead of the command specified in the Dockerfile.

## Running the App and Tests with Docker Compose

The `docker-compose-dev.yaml` file looks like this:

```
version: '3'
services:
  react-app:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "3000:3000"
    volumes:
      - /app/node_modules
      - .:/app
  test:
    build:
      context: .
      dockerfile: Dockerfile.dev
    volumes:
      - /app/node_modules
      - .:/app
    command: ["npm", "run", "test"]
```

It specifies two services. The first service is the called `react-app`. It builds the image using the `Dockerfile.dev` file. It maps the port 3000 on the host to port 3000 on the container so we can access it in the browser. This is the same as the `-p 3000:3000` flag we used in the previous step. It mounts two volumes:

- The `node_modules` folder in the container to the `node_modules` folder on the host. This makes it so that we use the `node_modules` installed within the container (rather than the current working directory that we map next). This is the same as the `-v /app/node_modules` flag we used in the previous step.
- The current directory on the host to the `/app` folder in the container. This makes it so that we don't have to rebuild the image every time we make a change to the code.

To run the app and tests with Docker Compose, run the following command:

```
docker-compose -f docker-compose-dev.yaml up --build
```

Notice that we can't interact with the tests. This is because the tests run in the background. To run the tests interactively, we can run the following command:

```
docker-compose -f docker-compose-dev.yaml run test
```

## What about Dockerfile and docker-compose.yaml?

The `Dockerfile` and `docker-compose.yaml` files are used for production. They are not used for development. The `Dockerfile.dev` and `docker-compose-dev.yaml` files are used for development - as you saw in the above steps.

The Dockerfile looks like this:

```
# Specify a base image
FROM node:18.13.0-alpine as builder

# Set working directory to user app folder
WORKDIR '/app'

# Copy package.json and install depenendencies
COPY package.json .
RUN npm install

# Copy all the other files
COPY ./ ./

# Run Build
RUN npm run build

# Use nginx as the base image
FROM nginx:latest

# Copy the build directory to nginx
COPY --from=builder /app/build /usr/share/nginx/html
```

This file does similar steps as the `Dockerfile.dev` file. The main difference is that it runs the `npm run build` command to build the app for production. It then uses the `nginx:latest` image as the base image. It copies the build directory to the nginx directory. No command is specified in the Dockerfile. This is because the default command for the nginx image is to start the nginx server.

# CI/CD with GitHub Actions to Netlify

**Note:** You do not need to use GitHub actions to deploy to Netlify. You can use Netlify's GitHub integration to deploy to Netlify directly. However, we will use GitHub actions to deploy to Netlify so you can see how to use GitHub actions, after showing you how to use Netlify's GitHub integration.

## What is Netlify?

Netlify is a CI/CD tool that allows you to deploy and host your app to the web. It started with static site hosting but now supports frameworks with servers with the use of serverless functions.

You can connect GitHub repositories to Netlify. When you push code to a connected repository, Netlify will automatically build and deploy the app. We will start with this so you can see how easy it is to deploy to Netlify. Then we will add integration tests to the CI/CD pipeline using GitHub actions.

## Connecting Netlify to GitHub

To connect Netlify to GitHub:

- Go to [Netlify Signup](https://app.netlify.com/signup)
- Sign up using your GitHub account.
- Click on the `Authorize netlify` button.
- When given the option, choose `Import an existing project` -> `Import from Git`
- Choose the repository you created
- Click on the `Deploy site` button.

You should see a message that says `Your site is building`. Once the build is complete, you should see a message that says `Your site is live`. You can click on the `View site` button to see your app.

## Running Tests with Netlify Build

The simplest way to get netlify to run your tests is to:

- Go to `Site settings` -> `Build & deploy` -> `Build settings`
- Click on the `Edit settings` button
- Update the `build` command to:

```
npm run test && npm run build
```

This will run the tests and then build the app if the tests pass. If the tests fail, the build will fail.

To verify this, you can make a change to the code that will cause the tests to fail (or write a new failing test). Then push the code to GitHub. You should see that the build fails. You can see an example of failing tests [here](https://github.com/micleners/ci-cd-webgeeks-feb-2023/pull/1).

## Using GitHub Actions to Run Tests and Deploy to Netlify

> *An example of this workflow yaml can be found on the [`netlify-actions` branch](https://github.com/micleners/ci-cd-webgeeks-feb-2023/blob/netlify-actions/.github/workflows/ci.yml) of this repository.*

While the previous method works, it is not ideal. If we had further tests we needed to run, or if we wanted to run our tests in docker, this would get complicated with the Netlify build settings. Instead, we will use GitHub actions to run our tests.

To do this, we will create a new workflow file in the `.github/workflows` directory. The file should be named `ci.yaml`. It should look like this:

```
name: CI

on:
  push:
    branches:
      - netlify-actions

jobs:
  build:
    runs-on: ubuntu-20.04

    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - run: docker build -t react-test -f Dockerfile.dev .
      - run: docker run -e CI=true react-test npm test
      - name: Publish
        uses: jsmrcaga/action-netlify-deploy@v1.1.0
        with:
          NETLIFY_AUTH_TOKEN: ${{ secrets.MY_TOKEN_SECRET }}
          NETLIFY_DEPLOY_TO_PROD: true
          NETLIFY_SITE_ID: UPDATE_WITH_YOUR_SITE_ID
```

Before this will work, there are a few things we need to do.

- Disconnect our repository from Netlify
- Get the Netlify site ID
- Create a Netlify access token
  See directions below.

### Disconnect our repository from Netlify

Unlinking your repository from Netlify will make it so pushes to your repository no longer trigger deploys to github. This is because we want to use GitHub actions to deploy to Netlify.

To do this:

- Go to [Netlify](https://app.netlify.com/)
- Go to the site you created by connecting it to the GitHub repository
- Click on `Site settings` then `Build & deploy`
- Click on `Manage repository` and then `Unlink <YOUR REPOSITORY>`

### Get the Netlify site ID

You will need to get the Netlify site ID for our GitHub action. To do this:

- Go to [Netlify](https://app.netlify.com/)
- Go to the site you created by connecting it to the GitHub repository
- Click on `Site settings` then `General`
- Copy the `Site ID` value
- Place it in your `ci.yaml` file in the `NETLIFY_SITE_ID` field

### Create a Netlify Access Token

You will need to create a Netlify access token. To do this:

- Go to [Netlify](https://app.netlify.com/)
- Click on your profile picture in the top right corner
- Click on `User settings`
- Click on `Applications`
- Under `Personal access tokens`, click on `New access token`
- Give the token a name and click on the `Create token` button
- **IMPORTANT:** Do not share this token. Copy the access key and secret access key - once you navigate away from the page AWS will not reveal the key to you again.
- Copy the token and go to your GitHub repository.
- Go to `Settings` -> `Secrets and Variables` -> `Actions`
- Click on the `New repository secret` button
- Gve the secret the name `MY_TOKEN_SECRET` and store the access token value here
- Click on the `Add secret` button

### Pushing Code

Commit and push and you should have a functional CI/CD pipeline testing your code before building and deploying to Netlify.

You'll notice that within the build step, GitHub actions is now building the site and pushing the deploy to Netlify. This contrasts with the previous method where Netlify was building the site and pushing the deploy. This is the desired behavior, allowing us to have more control over the build and deploy process.

# CI/CD with TravisCI to AWS Elastic Beanstalk

## What is TravisCI?

TravisCI is a CI/CD tool that is built into GitHub. It allows you to automate workflows. It is similar to GitHub Actions and CircleCI.

## Connecting TravisCI to GitHub

To connect TravisCI to GitHub, go to [travis-ci.com](https://travis-ci.com/). Then click on the `Sign in with GitHub` button. Then click on the `+` button next to your GitHub username. Then click on the `Activate` button next to the repository you want to connect to TravisCI. For more details on this, check out the [TravisCI documentation](https://docs.travis-ci.com/user/tutorial/#to-get-started-with-travis-ci-using-github) or this [blog](https://blog.travis-ci.com/2019-05-30-setting-up-a-ci-cd-process-on-github).

## Creating a TravisCI Workflow

> *An example of this workflow yaml can be found on the [`travis-ci` branch](https://github.com/micleners/ci-cd-webgeeks-feb-2023/blob/travis-ci/.travis.yml) of this repository.*

To create a workflow, create a `.travis.yml` file in the root of the project. The file should look like this:

```
sudo: required
services:
  - docker

before_install:
  - docker build -f Dockerfile.dev -t my_image .

script:
  - docker run -e CI=true my_image npm run test
# deploy:
#   provider: elasticbeanstalk
#   access_key_id: $AWS_ACCESS_KEY
#   secret_access_key: $AWS_SECRET_KEY
#   region: "us-east-2"
#   app: "UPDATE_WITH_YOUR_APPLICATION_NAME"
#   env: "UPDATE_WITH_YOUR_ENV_NAME"
#   bucket_name: "UPDATE_WITH_YOUR_BUCKET_NAME"
#   bucket_path: "UPDATE_WITH_YOUR_ENV_NAME"
#   on:
#     branch: main
```

Breaking down the file:

- The `sudo` field specifies that we need root access to run the build. This is because we need to run docker commands.
- The `services` field specifies the services we need to run the build. In this case, we need to run the docker service.
- The `before_install` field specifies the commands that need to be run before the build. In this case, we need to build the image using the `Dockerfile.dev` file.
- The `script` field specifies the commands that need to be run during the build. In this case, we need to run the tests in the container. This will run our tests and exit the container. If the tests fail, the build will fail.
- The `deploy` field specifies the commands that need to be run after the build. In this case, we will deploy the app to AWS Elastic Beanstalk. This is commented out because we don't have an AWS account yet. We will uncomment this later.

Committing and pushing this code to GitHub will trigger a build on TravisCI. You can see the build status on the TravisCI website. If the build fails, you can click on the build to see the logs. You can also see the build status on the GitHub repository. The build should pass because there is only one test that runs.

## Deploying to AWS Elastic Beanstalk for TravisCI

### Creating Elastic Beanstock in AWS for TravisCI

To deploy to AWS Elastic Beanstalk, you will need to

- Log into your AWS account
- Navigate to the Elastic Beanstalk service
- Create an Elastic Beanstalk application with the following:
  - Your choice of name
  - Platform: Docker
  - Sample application
  - **Note:** Application name will be used for `UPDATE_WITH_YOUR_APPLICATION_NAME` from the `.travis.yml` file
- This will automatically create an environment for you.
  - **Note:** Environment name will be used for `UPDATE_WITH_YOUR_ENV_NAME` from the `.travis.yml` file
- Create an IAM user with the following permissions:
  - AdministratorAccess-AWSElasticBeanstalk
- Create an access key for the user - currently this can be found by going to:
  - IAM
  - Users
  - Your User (the one you just created)
  - Security Credentials
  - Access Keys
  - Create New Access Key
  - On `Access key best practices & alternatives`, pick `Third-party service`, check you understand their recommendation and click continue (or figure out how to follow their direction about using IAM role instead)
  - **IMPORTANT:** Do not share this token. Copy the access key and secret access key - once you navigate away from the page AWS will not reveal the key to you again.
- Add the access key to TravisCI
- Navigate to S3 and find the name of the bucket created for your Elastic Beanstalk application
  - **Note:** Bucket name will be used for `UPDATE_WITH_YOUR_BUCKET_NAME` from the `.travis.yml` file

### In TravisCI

Go to the lastest build on TravisCI. Then click on the `More options` button. Then click on `Settings`. Then add the following environment variables:

- AWS_ACCESS_KEY -> from the IAM user you created noted **IMPORTANT** above
- AWS_SECRET_KEY -> from the IAM user you created noted **IMPORTANT** above
  Make sure both leave `DISPLAY VALUE IN BUILD LOG` unchecked - we do not want these values to be displayed in the build log.

### In travis.yml

Uncomment the `deploy` section in the `.travis.yml` file. Then update the following fields:

- `UPDATE_WITH_YOUR_APPLICATION_NAME` -> the name of the Elastic Beanstalk application you created
- `UPDATE_WITH_YOUR_ENV_NAME` -> the name of the Elastic Beanstalk environment you created
- `UPDATE_WITH_YOUR_BUCKET_NAME` -> the name of the directory within the S3 bucket that is generated for your Elastic Beanstalk application. It should contain the word `elasticbeanstalk` and the region you are using.
- **Note:** Update `region` if your region is not `us-east-2`

Push your code to GitHub. This will trigger a build on TravisCI. The build should pass and the app should be deployed to AWS Elastic Beanstalk.

# CI/CD with GitHub Actions to AWS Elastic Beanstalk

## What is GitHub Actions?

GitHub Actions are a CI/CD tool that is built into GitHub. It allows you to automate workflows. It is similar to TravisCI and CircleCI.

## Creating a Github Actions Workflow

> *An example of this workflow yaml can be found on the [`github-actions` branch](https://github.com/micleners/ci-cd-webgeeks-feb-2023/blob/github-actions/.github/workflows/ci.yml) of this repository.*

To create a workflow, create a `.github/workflows` folder in the root of the project. Then create a file called `ci.yml` in the folder. The file should look like this:

```
name: CI

on:
  push:
    branches:
      - main

# env:
#   AWS_ACCESS_KEY: ${{ secrets.AWS_ACCESS_KEY }}
#   AWS_SECRET_KEY: ${{ secrets.AWS_SECRET_KEY }}

jobs:
  build:
    runs-on: ubuntu-20.04

    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - run: docker build -t react-test -f Dockerfile.dev .
      - run: docker run -e CI=true react-test npm test

      # - name: Generate deployment package
      #   run: zip -r deploy.zip . -x '*.git*'

      # - name: Deploy to EB
      #   uses: einaregilsson/beanstalk-deploy@v21
      #   with:
      #     aws_access_key: ${{ env.AWS_ACCESS_KEY }}
      #     aws_secret_key: ${{ env.AWS_SECRET_KEY }}
      #     region: us-east-2
      #     application_name: UPDATE_WITH_YOUR_APPLICATION_NAME
      #     environment_name: UPDATE_WITH_YOUR_ENV_NAME
      #     existing_bucket_name: UPDATE_WITH_YOUR_BUCKET_NAME
      #     version_label: ${{ github.sha }}
      #     deployment_package: deploy.zip
      #     use_existing_version_if_available: true
```

Breaking down the file:

- The `name` field specifies the name of the workflow.
- The `on` field specifies the events that trigger the workflow. In this case, the workflow is triggered when a push is made to the `main` branch.
- The `jobs` field specifies the jobs that are run in the workflow. In this case, there is only one job called `build`.
- The `runs-on` field specifies the operating system that the job runs on. In this case, it runs on Ubuntu 20.04.
- The `steps` field specifies the steps that are run in the job. In this case, there are three steps:
  - The first step checks out the code from the repository.
  - The second step builds the image using the `Dockerfile.dev` file.
  - The third step runs the tests in the container.
- If the tests fail, the workflow fails.

## Deploying to AWS Elastic Beanstalk for GitHub Actions

### Creating Elastic Beanstock in AWS for GitHub Actions

To deploy to AWS Elastic Beanstalk, you will need to

- Log into your AWS account
- Navigate to the Elastic Beanstalk service
- Create an Elastic Beanstalk application with the following:
  - Your choice of name
  - Platform: Docker
  - Sample application
  - **Note:** Application name will be used for `UPDATE_WITH_YOUR_APPLICATION_NAME` from the `ci.yml` file
- This will automatically create an environment for you.
  - **Note:** Environment name will be used for `UPDATE_WITH_YOUR_ENV_NAME` from the `ci.yml` file
- Create an IAM user with the following permissions:
  - AdministratorAccess-AWSElasticBeanstalk
- Create an access key for the user - currently this can be found by going to:
  - IAM
  - Users
  - Your User (the one you just created)
  - Security Credentials
  - Access Keys
  - Create New Access Key
  - On `Access key best practices & alternatives`, pick `Third-party service`, check you understand their recommendation and click continue (or figure out how to follow their direction about using IAM role instead)
  - **IMPORTANT:** Do not share this token. Copy the access key and secret access key - once you navigate away from the page AWS will not reveal the key to you again.
- Add the access key to GitHub
- Navigate to S3 and find the name of the bucket created for your Elastic Beanstalk application
  - **Note:** Bucket name will be used for `UPDATE_WITH_YOUR_BUCKET_NAME` from the `ci.yml` file

### In GitHub

We need to add our AWS access key and secret key to GitHub. To do this:

- Go to `Settings` -> `Secrets and Variables` -> `Actions`
- Click on the `New repository secret` button
- Gve the secret the name `MY_TOKEN_SECRET` and store the access token value here
- Click on the `Add secret` button

### In ci.yml

Uncomment the `deploy` and `env` sections in the `ci.yml` file. Then update the following fields:

- `UPDATE_WITH_YOUR_APPLICATION_NAME` -> the name of the Elastic Beanstalk application you created
- `UPDATE_WITH_YOUR_ENV_NAME` -> the name of the Elastic Beanstalk environment you created
- `UPDATE_WITH_YOUR_BUCKET_NAME` -> the name of the directory within the S3 bucket that is generated for your Elastic Beanstalk application. It should contain the word `elasticbeanstalk` and the region you are using.
- **Note:** Update `region` if your region is not `us-east-2`

Push your code to GitHub and watch the workflow run. If the tests pass, the workflow will deploy to AWS Elastic Beanstalk.
