# UniFi DreamMachine Sinatra API

This project comprises a Dockerized Sinatra application that serves as a proxy for the UniFi DreamMachine API. The primary function of this application is to allow simple toggling of traffic rules on a UniFi network.

## Use Case

This Sinatra application is designed for environments where frequent toggling of internet access rules is needed, such as in a home with children who have restrictions on their internet usage.

Imagine you want to limit your children's internet access to only certain educational websites until their homework is completed. Once they finish their assignments, you can easily enable broader internet access with a simple button click. This is particularly useful for individuals who are not technically inclined or those who do not require full administrative access to the UniFi console, like babysitters or grandparents.

Although it's technically feasible to set up a Shortcut that communicates directly with the UniFi API, this approach has several drawbacks. For instance, it would require you to be on the same local network as the target UniFi device. By using this Sinatra application within a Docker container as a proxy, you can access the proxy via several different means and expose only certain actions via the API.

## Prerequisites

- Docker installed on your machine.
- Familiarity with Docker commands and YAML syntax.
- Access to a UniFi DreamMachine and the login credentials.

## Setup Instructions

1. Clone the repository to your local machine.

2. Update the `docker-compose.yml` file with your UniFi DreamMachine login credentials and network details:

    ```yaml
    version: '3'
    services:
      unifi_dreammachine_sinatra_api:
        image: konung/unifi_dreammachine_sinatra_api:latest
        ports:
          - "4657:4567"
        environment:
          USERNAME: 'your_username'
          PASSWORD: 'your_password'
          # Site name is usually - default
          SITE_NAME: 'default'
          BASE_URL: 'https://ip_address_of_your_dreammachine:443'
          # This will need to be submitted and sent as part of your api reguest from external apps/shortcuts,etc
          API_TOKEN: SOME_VERY_LONG_AND_SECURE_TOKEN
    ```

3. Build and run the Docker container or if you are using portainer - you can just start a stack :

    ```bash
    docker-compose up -d
    ```

    The Sinatra application is now ready to accept requests.

## How to access Sinatra app Docker image

Depending on settings in your Docker setup it should now be running on port 4657. i.e http://my-docker-host:4657
Example config: Synology/QNAP/TrueNas NAS, running docker containers - this makes it avaible on the local network.

To make it accessable from outside (DO THIS ONLY AT YOUR OWN RISK!), you can try several approaches:

1. Setting up TailScale / WireGuard to run it on a mash network - if you set it up on your phone - you can access your docker container from anywhere ( probably a better approach )
2. Setting up some kind of dyndns service like afraid.org with portforwarding. ( less secure )
3. Running docker container on a VPS outside of your network, with VPS having a VPN site-to-site link back to your Dream Machine ( while this is possible, this is not recommended as it's difficult to secure )

## Usage

This application provides several endpoints for managing UniFi traffic rules:
- `/toggle?api_token=SOME_VERY_LONG_AND_SECURE_TOKEN&rule_id=ALPHANUMERIC_RULE_ID` Toggles the state of the traffic rule (enabled/disabled) at the specified site.
- `/status?api_token=SOME_VERY_LONG_AND_SECURE_TOKEN`: Fetches the current status of all traffic rules for the specified site.

The Sinatra app serves as a proxy to your UniFi DreamMachine, so you can make these requests from anywhere, not just your local network. You can even integrate these endpoints into other systems, like MacOS & iOS shortcuts in Shortcut.app, to control traffic rules with the click of a button.


Final url example:
`https://my.tailscale.wiregurard.someothervpn.setup.net:4657/status?api_token=SOME_VERY_LONG_AND_SECURE_TOKEN`

Now that you have this link + endpoint, it's fairly easy to setup a script or cli command that just hits that URL. Setting up a shortcut in Shortcuts.app is also straightforward.

## Security

This application requires **local** UniFi credentials to operate, and allowing only predefined actions to be performed. However, remember to always follow best practices when exposing any application on the internet. Consider using HTTPS and restricting access to known IP addresses whenever possible.

# Customizing
- See `unifi_api.rb` for a sample of various actions. Feel free to add more.
- See [https://ubntwiki.com/products/software/unifi-controller/api](https://ubntwiki.com/products/software/unifi-controller/api) for reference of available endpoints
- See `app.rb` - for Sinatra app that exposes `unifi_api.rb`
- [UniFi-API-client](https://github.com/Art-of-WiFi/UniFi-API-client/) and [UniFI-API-browser](https://github.com/Art-of-WiFi/UniFi-API-browser) are also excellent references.

# Aknowledgement

None of this would be possible without [Ubiquiti](https://store.ui.com/us/en/pro/category/all-unifi-gateway-consoles/products/udm) and their excellent networking equipment and the work of [Art-of-WiFi](https://artofwifi.net)
