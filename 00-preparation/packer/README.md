To build the AMI in AWS and publish metadata to HCP Packer the following prerequisites must be in place:

- Install Packer (see [instructions](https://developer.hashicorp.com/packer/install))
- AWS credentials available in your environment, for instance by [installing and configuring the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [Create an HCP service principal with credentials](https://developer.hashicorp.com/hcp/docs/hcp/admin/iam/service-principals). Create a file named `hcp.env` in this directory and add the following content:
    ```env
    HCP_CLIENT_ID="<client id>"
    HCP_CLIENT_SECRET="<client secret>"
    HCP_PROJECT_ID="<hcp project id>"
    ```

To initiate the build run:

```shell
$ chmod +x build.sh
$ ./build.sh
```