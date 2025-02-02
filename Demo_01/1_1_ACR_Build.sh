# DEMO 1 - Building custom MSSQL-Tools image with ACR
#
#   1- Create Azure Container Registry
#   2- List ACR registry
#   3- Inspect Dockerfile
#   4- Build local image - mssqltools
#   5- Get image metadata
#   6- Test custom image with a container
#   7- Tag and push local image to ACR repository
#   8- Check ACR repositories + images with VS Code Docker extension
#   9- Build and push image with Azure Cloud shell (single instruction)
#   10- List images in ACR repository

# -----------------------------------------------------------------------------
# References:
#   Azure Container Registry authentication with service principals
#   open https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-service-principal
#   open https://docs.microsoft.com/en-us/azure/container-registry/container-registry-authentication
#
#   Azure CLI - ACR commands reference
#   open https://docs.microsoft.com/en-us/cli/azure/acr?view=azure-cli-latest

# 0- Env variables | demo path
resource_group=24-horas-azure;
acr_name=dbamastery;
acr_repo=mssqltools-alpine;
location=westus;
cd ~/Documents/$resource_group/Demo_01;
az acr login --name $acr_name;
sa_password=_SqLr0ck5_;

# 1- Create Azure Container Registry
# Create Resource group
# az group create --name $resource_group --location $location

# Create container registry
az acr create --resource-group $resource_group --name $acr_name --sku Standard --location $location

# 2- List ACR registry
az acr list --resource-group $resource_group -o table

# 3- Inspect Dockerfile
# Custom mssqltools image with Alpine
code Dockerfile

# 4- Build local image - mssqltools
docker build . -t mssqltools-alpine -f Dockerfile

# 5- Get image metadata
# List local image
docker images mssqltools-alpine

# Getting image metadata
docker inspect mssqltools-alpine | jq -r '.[0].Config.Labels'

# 6- Test custom image with a container
# Creating SQL Server 2019 container
docker container run \
    --name 24-horas-azure \
    --hostname 24-horas-azure \
    --env 'ACCEPT_EULA=Y' \
    --env 'SA_PASSWORD=_SqLr0ck5_' \
    --publish 1433:1433 \
    --detach mcr.microsoft.com/mssql/server:2019-CU4-ubuntu-18.04

# Test mssqltools-alpine image / container
docker container run \
    --network host \
    mssqltools-alpine \
    sqlcmd -S localhost -U SA -P $sa_password -Q "set nocount on; select @@servername;"

# 7- Tag and push local image to ACR repository
# Getting image id
image_id=`docker images | grep mssqltools-alpine | awk '{ print $3 }' | head -1`

# Tagging image with private registry and build number
# ACR FQN = dbamastery.azurecr.io/mssqltools-alpine:2.0
docker tag $image_id $acr_name.azurecr.io/$acr_repo:2.0
docker images

# Pushing image to ACR (dbamastery) - mssqltools-alpine repository
# Make sure to check ACR authentication and login process with Docker first
docker push $acr_name.azurecr.io/$acr_repo:2.0

# --------------------------------------
# Visual Studio Code extension - step
# --------------------------------------
# 8- Check ACR repositories + images with VS Code Docker extension 👀

# 9- Build and push image with Azure Cloud shell (single instruction)
# No Docker, no problem 👍👌

# Navigate to Azure portal and start a new Azure Cloud shell session
open https://portal.azure.com

# Navigate to cloud share
cd clouddrive/PASS-Marathon/Demo_01
ls -ll

# Build, tag and push in a single instruction
az acr build --image mssqltools-alpine:2.1 --registry dbamastery .

# 10- List images in ACR repository
az acr repository show --name $acr_name --repository $acr_repo -o table
az acr repository show-manifests --name $acr_name --repository $acr_repo
az acr repository show-tags --name $acr_name --repository $acr_repo --detail
az acr task logs --registry $acr_name