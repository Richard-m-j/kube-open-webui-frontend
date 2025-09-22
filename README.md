# Kube OpenWebUI Frontend

This repository contains the frontend for the Ollama Model Manager, a Vue 3 application built with Vite. It provides a user-friendly interface for managing AI models in an Ollama engine.

## Features

  * **Vue 3 and Vite**: A modern and fast frontend stack.
  * **Model Management**: View local models, discover popular models, and pull new models from Ollama.
  * **Dockerized**: Comes with a multi-stage Dockerfile for building and serving the application with Nginx.
  * **Kubernetes-Native**: Includes a full set of Kubernetes manifests for deployment.
  * **Automated CI/CD**: A complete CI/CD pipeline using GitHub Actions for automated builds, tests, and deployments.

## Getting Started

To run the application locally, you will need to have Node.js and npm installed.

1.  Clone the repository:
    ```bash
    git clone https://github.com/Richard-m-j/kube-open-webui-frontend.git
    ```
2.  Navigate to the project directory:
    ```bash
    cd kube-open-webui-frontend
    ```
3.  Install the dependencies:
    ```bash
    npm install
    ```
4.  Start the development server:
    ```bash
    npm run dev
    ```

## Kubernetes Deployment

To deploy the application to a Kubernetes cluster, you can use the manifests provided in the `kubernetes` directory.

1.  Apply the manifests:
    ```bash
    kubectl apply -f kubernetes/
    ```

This will create all the necessary Kubernetes resources, including the deployment, service, ingress, network policy, and HPA.

## CI/CD Pipeline

The repository has a comprehensive CI/CD pipeline that automates the build, test, and deployment process. The pipeline is defined in the `.github/workflows/ci-cd.yml` file and consists of the following workflows:

  * **Lint & Build**: Lints the code and builds the application.
  * **Security Scans**: Performs Software Component Analysis (SCA) and secret scanning.
  * **CodeQL Analysis**: Uses GitHub's CodeQL for in-depth static analysis.
  * **Build, Push & Update Manifest**: Builds and pushes a new Docker image, updates the Kubernetes manifest with the new image tag, and commits the change back to the repository.

## Configuration

The application is configured to be served under the `/modelmanager/` path. This is set in the `vite.config.js` file and the `nginx.conf` file. The frontend communicates with the backend service through a proxy, which is also configured in the `nginx.conf` file.

## Contributing

Contributions are welcome\! Please feel free to submit a pull request or open an issue.

## License

This project is licensed under the MIT License.