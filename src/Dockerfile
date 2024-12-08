FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build-env

ENV NUGET_XMLDOC_MODE=none

WORKDIR /app

COPY . ./

#clean all existing binaries
RUN find -type d -name bin -prune -exec rm -rf {} \; && find -type d -name obj -prune -exec rm -rf {} \;

WORKDIR /app/OpenLearning.API
RUN dotnet clean;

RUN dotnet publish -c Release -o out GOpenLearning.API.csproj

# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine
WORKDIR /app
COPY --from=build-env /app/OpenLearning.API/out/ .

# Disable the invariant mode (set in base image)
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false

#Explicitly set the ASPNETCORE_HTTP_PORTS, ASPNETCORE_HTTPS_PORTS, and ASPNETCORE_URLS environment variables to the desired port
#https://learn.microsoft.com/en-us/dotnet/core/compatibility/containers/8.0/aspnet-port#recommended-action
ENV ASPNETCORE_HTTP_PORTS=80

ENTRYPOINT ["dotnet", "OpenLearning.API.dll"]