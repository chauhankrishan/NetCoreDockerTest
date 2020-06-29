#See https://aka.ms/containerfastmode to understand how Visual Studio uses this Dockerfile to build your images for faster debugging.

FROM mcr.microsoft.com/dotnet/core/aspnet:3.1-buster-slim AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443


FROM mcr.microsoft.com/dotnet/core/sdk:3.1-buster AS build
WORKDIR /src
COPY NetCoreDockerTest/NetCoreDockerTest.csproj NetCoreDockerTest/
RUN dotnet restore "NetCoreDockerTest/NetCoreDockerTest.csproj"
COPY . .
WORKDIR "/src/NetCoreDockerTest"
RUN dotnet build "NetCoreDockerTest.csproj" -c Release -o /app/build

#######################################################
# Step 1: Build the application in a container        #
#######################################################
# Download the official ASP.NET Core SDK image
# to build the project while creating the docker image
ARG SONAR_PROJECT_KEY=robinmanuelthiel_microcommunication
ARG SONAR_OGRANIZAION_KEY=robinmanuelthiel
ARG SONAR_HOST_URL=https://sonarcloud.io
ARG SONAR_TOKEN

# Install Sonar Scanner, Coverlet and Java (required for Sonar Scanner)
RUN apt-get update && apt-get install -y openjdk-11-jdk
RUN dotnet tool install --global dotnet-sonarscanner
RUN dotnet tool install --global coverlet.console
ENV PATH="$PATH:/root/.dotnet/tools"

# Start Sonar Scanner
RUN dotnet sonarscanner begin \
  /k:"$f1a4d3e46eb84febecbaa8c0557be5033f81392d" \
  /o:"$admin" \
  /d:sonar.host.url="$http://3.236.140.107:9000/" \
  /d:sonar.login="$f42685204feb35acc9291af870a68c9479f02f81" \
  /d:sonar.cs.opencover.reportsPaths=/coverage.opencover.xml

  
# Restore NuGet packages
COPY *.csproj .
RUN dotnet restore

# Copy the rest of the files over
COPY . .

FROM build AS publish
RUN dotnet publish "NetCoreDockerTest.csproj" -c Release -o /app/publish

RUN dotnet test \
  /p:CollectCoverage=true \
  /p:CoverletOutputFormat=opencover \
  /p:CoverletOutput="/coverage"

# End Sonar Scanner
RUN dotnet sonarscanner end /d:sonar.login="$f42685204feb35acc9291af870a68c9479f02f81"

#######################################################
# Step 2: Run the build outcome in a container        #
#######################################################
# Download the official ASP.NET Core Runtime image
# to run the compiled application
FROM mcr.microsoft.com/dotnet/core/aspnet:3.1
WORKDIR /app/publish


FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Open port
EXPOSE 8080

ENTRYPOINT ["dotnet", "NetCoreDockerTest.dll"]


