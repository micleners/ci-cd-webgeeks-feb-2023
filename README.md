# CI/CD with React, Docker, TravisCI, Github Actions and Netlify

This project is a simple React app that can be built locally with Docker and deployed to Netlify or AWS using TravisCI or Github Actions.

## Notes about the Project

The `Dockerfile` and `docker-compose.yaml` files are used for production. They are not used for development. The `Dockerfile.dev` and `docker-compose-dev.yaml` files are used for development - as you saw in the above steps.

**Notes:**
- The `--build` flag is only needed the first time you run the command.
- If you get an error about the port being in use, you can run `docker-compose -f docker-compose-dev.yaml down` to stop the containers. Or run `docker stop $(docker ps -aq) && docker rm $(docker ps -aq)` to stop and remove all containers.

Everything in this tutorial is free EXCEPT:
- AWS Elastic Beanstalk can be free for new users, otherwise, it will cost money. Make sure you tear down the Elastic Beanstalk instance when you are done.
- TravisCI offers a trial period for new users. After the trial period, you will have to pay for the service. Make sure you tear down the TravisCI pipelines when you are done.

To follow this tutorial, you need to have the following:
- Docker installed locally
- A Github account (to push this code to and connect to TravisCI and Netlify, to run GitHub Actions)
- A TravisCI account (to run the CI/CD pipeline and deploy to AWS)
- A Netlify account (to deploy the app)
- An AWS account (to create an Elastic Beanstalk instance to deploy from TravisCI and GitHub Actions)


## Local Setup

To use this project run locally:

```
git clone https://github.com/micleners/ci-cd-webgeeks-feb-2023.git
cd ci-cd-webgeeks-feb-2023
```

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
docker build -f Dockerfile.dev -v -t simple-react .
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

# Connect Your Local Code to a GitHub Repository

To use any of the CI/CD tools discussed here, you need to connect your local code to a GitHub repository. To do this, create a new repository on GitHub. Then run the following commands, where `<url>` is the url of the GitHub repository you created

```
git remote add origin <url>
git add .
git commit -m "Initial commit"
git push -u origin master
```

You should now see the code on your GitHub repository.

# CI/CD with TravisCI

## What is TravisCI?

TravisCI is a CI/CD tool that is built into GitHub. It allows you to automate workflows. It is similar to GitHub Actions and CircleCI.

## Connecting TravisCI to GitHub

To connect TravisCI to GitHub, go to [travis-ci.com](https://travis-ci.com/). Then click on the `Sign in with GitHub` button. Then click on the `+` button next to your GitHub username. Then click on the `Activate` button next to the repository you want to connect to TravisCI. For more details on this, check out the [TravisCI documentation](https://docs.travis-ci.com/user/tutorial/#to-get-started-with-travis-ci-using-github) or this [blog](https://blog.travis-ci.com/2019-05-30-setting-up-a-ci-cd-process-on-github).

## Creating a TravisCI Workflow

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

## Deploying to AWS Elastic Beanstalk

### In AWS

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
  - **IMPORTANT:** Copy the access key and secret access key - once you navigate away from the page AWS will not reveal the key to you again.
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

# CI/CD with GitHub Actions

## What is GitHub Actions?

GitHub Actions are a CI/CD tool that is built into GitHub. It allows you to automate workflows. It is similar to TravisCI and CircleCI.


## Creating a Github Actions Workflow

To create a workflow, create a `.github/workflows` folder in the root of the project. Then create a file called `ci.yml` in the folder. The file should look like this:

```
name: CI

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-20.04

    steps:
      - name: Checkout code
        uses: actions/checkout@v2
      - run: docker build -t react-test -f Dockerfile.dev .
      - run: docker run -e CI=true react-test npm test
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
